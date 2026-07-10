# Mini-IPTV Backend MVP

Backend FastAPI para a Mini-IPTV. O Apache em R1 termina HTTPS e encaminha apenas `/api/*` para este servico no host S.

## Variaveis de ambiente

- `DATABASE_URL`: SQLite local, por exemplo `sqlite:///./mini_iptv.sqlite3`.
- `IPTV_GROUP_ID`: ID numerico do grupo usado nos enderecos multicast.
- `WAN_CIDRS`: faixas que representam X e Y na WAN115K, separadas por virgula.
- `MEDIA_ROOT`: raiz dos arquivos de midia ja presentes no host S.
- `SESSION_TIMEOUT_SECONDS`: tempo sem heartbeat para expirar uma sessao ativa. Padrao: `60`.
- `OIDC_ISSUER_URL`: issuer do realm Keycloak, por exemplo `http://127.0.0.1:8080/realms/mini-iptv`.
- `OIDC_JWKS_URL`: endpoint JWKS do realm, por exemplo `http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/certs`.
- `OIDC_AUDIENCE`: client OIDC esperado, por padrao `mini-iptv-frontend`.

## Execucao

A partir da raiz do repositorio (`redes/`), entre na pasta do backend:

```bash
cd backend
python -m venv .venv
.venv/bin/python -m pip install -e .
DATABASE_URL=sqlite:///./mini_iptv.sqlite3 IPTV_GROUP_ID=7 WAN_CIDRS=192.168.0.0/24 MEDIA_ROOT=/srv/iptv \
OIDC_ISSUER_URL=http://127.0.0.1:8080/realms/mini-iptv \
OIDC_JWKS_URL=http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/certs \
OIDC_AUDIENCE=mini-iptv-frontend \
  .venv/bin/uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000
```

Para executar os testes automatizados:

```bash
.venv/bin/python -m pytest -q
```

Com o servidor em execucao, a documentacao interativa dos endpoints fica disponivel em:

```text
http://127.0.0.1:8000/api/docs
```

Essa pagina permite consultar os detalhes de cada rota e testar as requisicoes diretamente pelo Swagger UI.

Credenciais seed para desenvolvimento no Keycloak: `admin/admin123`, `cliente1/cliente123`, `cliente2/cliente123`.

O backend nao valida mais senha diretamente. Ele exige um JWT Bearer emitido pelo Keycloak local descrito em `../auth-server/README.md`.

## Contrato com Apache em R1

O backend deve ser acessado pelos clientes via Apache em R1, nao diretamente. Exemplo:

```apache
ProxyPreserveHost On
ProxyPass /api/ http://<IP_DE_S>:8000/api/
ProxyPassReverse /api/ http://<IP_DE_S>:8000/api/
RequestHeader append X-Forwarded-For %{REMOTE_ADDR}s
```

O backend classifica `WAN115K` quando o primeiro IP de `X-Forwarded-For` esta dentro de `WAN_CIDRS`; caso contrario usa `LAN`.

## Fluxo do frontend

1. Login: frontend redireciona o usuario para o Keycloak local.
2. Keycloak emite `access_token` JWT para o client `mini-iptv-frontend`.
3. Listar canais: `GET /api/canais` com `Authorization: Bearer <jwt>`.
4. Entrar no canal: `POST /api/canais/{id}/entrar`.
5. Baixar playlist: `GET /api/sessoes/{id}/playlist.m3u`.
6. Abrir no VLC Client o fluxo `udp://@<multicast>:5004`.
7. Manter sessao: `POST /api/sessoes/{id}/heartbeat`.
8. Sair: `POST /api/sessoes/{id}/sair`.

## Rotas administrativas para o frontend

As rotas abaixo exigem JWT de usuario `admin`:

- `GET /api/admin/dashboard`: resumo operacional, fluxos multicast e PIDs do VLC.
- `POST /api/admin/canais`, `PUT /api/admin/canais/{id}`, `DELETE /api/admin/canais/{id}`: manutencao de canais.
- `GET /api/admin/videos`: listagem de videos cadastrados para associacao aos canais.
- `POST /api/admin/videos`, `PUT /api/admin/videos/{id}`, `DELETE /api/admin/videos/{id}`: manutencao de referencias de video.
- `POST /api/admin/videos/{id}/metadata`: leitura de metadados via `ffprobe` a partir do `hd_path`.

## Expiracao de sessoes

O frontend envia heartbeat periodico para `POST /api/sessoes/{id}/heartbeat`. Se uma sessao ficar sem heartbeat por mais de `SESSION_TIMEOUT_SECONDS`, ela e desativada automaticamente nas proximas leituras de canais, acessos ao dashboard ou tentativas de entrada em canal. Quando a ultima sessao ativa de um canal/perfil expira, o backend encerra o stream VLC correspondente.

## Regras principais

- LAN usa `239.10.<grupo>.<canal>:5004` e arquivo HD/original.
- WAN115K usa `239.20.<grupo>.<canal>:5004` e arquivo LD.
- LAN pode ter varios canais ativos.
- WAN115K permite apenas um canal ativo por vez; outros usuarios WAN podem compartilhar o canal ativo.
- O processo `cvlc` inicia quando o primeiro usuario entra em um canal/perfil e para quando o ultimo sai.

## Status HTTP esperados

- `401`: token ausente, invalido ou expirado.
- `403`: usuario autenticado sem permissao, por exemplo cliente em rota admin.
- `404`: canal, video ou sessao inexistente.
- `409`: conflito WAN115K, com `active_channel` no corpo.

## Checklist de demonstracao

1. Admin faz login e abre `GET /api/admin/dashboard`.
2. Cliente LAN entra no canal 1 e recebe playlist HD em `239.10.<grupo>.1`.
3. Cliente WAN entra no canal 2 e recebe playlist LD em `239.20.<grupo>.2`.
4. Segundo cliente WAN tenta canal diferente e recebe `409`.
5. Segundo cliente WAN entra no mesmo canal e compartilha o stream.
6. Ultimo cliente sai e o stream correspondente e encerrado.
