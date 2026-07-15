# Proxy Reverso / API Gateway (Apache no R1)

Documentação do proxy reverso que roda no **Roteador R1**, a borda da intranet.
Ele faz três coisas: termina o TLS (HTTPS), serve o build do frontend React e
encaminha `/api/` para o backend no Host S.

Arquivos:

- `backend/deploy/apache-mini-iptv.conf` — o Virtual Host do Apache.
- `NetworkConfig/scripts/roteador-r1/r1proxy.sh` — script de deploy (idempotente).

---

## Por que o proxy existe

O backend **nunca** é acessado diretamente pelos clientes — sempre através do R1.
Isso não é só organização, é requisito de segurança do projeto:

1. **Terminação TLS.** Os clientes falam HTTPS com o R1; o R1 fala HTTP interno
   com o Host S (`172.16.0.2:8000`). O certificado é autoassinado (gerado pelo
   script), então o navegador exibe um aviso na primeira visita.

2. **Classificação LAN/WAN confiável.** O backend decide o perfil do usuário
   (`LAN` vs `WAN115K`) pelo **primeiro IP** do cabeçalho `X-Forwarded-For`. O
   Apache reescreve esse cabeçalho com `RequestHeader set X-Forwarded-For
   "%{REMOTE_ADDR}s"` — usando `set` (e não `append`), qualquer valor que o
   cliente tenha enviado é **descartado**. Assim um cliente WAN não consegue
   forjar um `X-Forwarded-For` para se passar por LAN e escapar do limite de banda.

3. **Frontend + API na mesma origem.** O React é servido na raiz (`/`) e a API
   em `/api/`, tudo no mesmo host HTTPS — sem CORS, sem porta extra exposta.

---

## Como o Virtual Host está montado

```apache
Define BACKEND_HOST 172.16.0.2      # Host S (ajustado pelo script de deploy)
Define BACKEND_PORT 8000
Define DOCROOT /var/www/mini-iptv   # build do frontend
```

**Porta 80 → 301 para 443:** todo tráfego HTTP é redirecionado para HTTPS
preservando host e caminho.

**Porta 443 (o gateway de verdade):**

| Rota            | Destino                                                        |
|-----------------|---------------------------------------------------------------|
| `/api/...`      | proxy → `http://172.16.0.2:8000/api/...` (backend no Host S)   |
| qualquer outra  | arquivos estáticos em `/var/www/mini-iptv`                     |

- `FallbackResource /index.html` faz o roteamento SPA: qualquer URL que não seja
  um arquivo real cai no `index.html` do React. As requisições `/api/` são
  tratadas pelo `mod_proxy` antes de chegar ao filesystem, então o fallback
  **não** as intercepta.
- `ProxyPreserveHost On` mantém o `Host` original na requisição ao backend.
- Logs em `${APACHE_LOG_DIR}/mini-iptv_{access,error}.log`.

---

## Deploy (no R1, como root)

```bash
cd NetworkConfig/scripts/roteador-r1
sudo ./r1proxy.sh                    # backend padrão: 172.16.0.2:8000
# ou apontando para outro host/porta:
sudo ./r1proxy.sh 172.16.0.2 8000
```

O script é idempotente e faz, em ordem:

1. Instala o `apache2`.
2. Habilita os módulos `ssl proxy proxy_http headers rewrite`.
3. Gera o certificado autoassinado em `/etc/ssl/mini-iptv/` (só se ainda não existir).
4. Cria o `DocumentRoot` `/var/www/mini-iptv` com um placeholder.
5. Instala o vhost em `sites-available/` e injeta `BACKEND_HOST`/`BACKEND_PORT`.
6. Ativa o site (`a2ensite`), desativa o `000-default`, roda `configtest` e reinicia.

### Publicar o frontend

O passo 4 só cria um placeholder. Após rodar o script, copie o build do React
para o DocumentRoot:

```bash
# na máquina de build:
cd frontend && npm run build
# copie o conteúdo de frontend/dist/ (ou build/) para o R1:
sudo cp -r dist/* /var/www/mini-iptv/
```

---

## Testes

A partir de um cliente (ou do próprio R1):

```bash
# 1. HTTP redireciona para HTTPS
curl -I http://<IP_DO_R1>/            # espera 301 -> https://

# 2. Frontend responde na raiz (-k: aceita cert autoassinado)
curl -k https://<IP_DO_R1>/           # espera o index.html do React

# 3. API é encaminhada ao backend
curl -k https://<IP_DO_R1>/api/docs   # Swagger UI do FastAPI

# 4. Perfil não pode ser forjado: mesmo enviando X-Forwarded-For, o Apache
#    sobrescreve com o IP real. O backend classifica pelo IP que o R1 enxerga.
curl -k -H "X-Forwarded-For: 10.10.10.10" https://<IP_DO_R1>/api/...
```

Validar a config sem reiniciar: `sudo apache2ctl configtest`.
Logs ao vivo: `sudo tail -f /var/log/apache2/mini-iptv_error.log`.
