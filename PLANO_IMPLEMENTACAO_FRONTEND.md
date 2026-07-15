# Plano de Implementacao do Frontend - Mini-IPTV

## 1. Objetivo

Implementar a interface web da Mini-IPTV em React, integrada ao contrato atual do backend FastAPI. O frontend deve permitir autenticacao, consulta de canais, entrada e saida de sessoes multicast, download da playlist `.m3u`, manutencao da sessao por heartbeat e administracao dos recursos ja expostos pela API.

Este plano considera o proxy reverso Apache fora do escopo desta etapa. Nenhuma URL de infraestrutura deve ser fixa no codigo; o acesso a API sera configurado por ambiente.

## 2. Escopo funcional

### Cliente autenticado

- Entrar com usuario e senha.
- Visualizar canais, descricao, status e quantidade de espectadores.
- Consultar detalhes do canal e do video associado.
- Entrar em um canal e receber o perfil determinado pelo backend (`LAN` ou `WAN115K`).
- Baixar a playlist autenticada e abri-la no VLC Client.
- Manter a sessao ativa com heartbeat periodico.
- Sair do canal ou trocar de canal, encerrando a sessao anterior.
- Receber uma mensagem clara quando outro canal ja estiver ocupando a WAN.

### Administrador

- Visualizar o dashboard operacional.
- Criar, editar e remover canais.
- Cadastrar, editar e remover referencias de videos por caminho no Host S.
- Solicitar a leitura de metadados de um video ja cadastrado.
- Associar um video existente a um canal.

Upload de arquivos e conversao com `ffmpeg` nao fazem parte do frontend desta versao porque o backend atual nao oferece esses endpoints.

## 3. Decisoes tecnicas

- React com TypeScript e Vite.
- Tailwind CSS para estilos.
- React Router para rotas publicas e protegidas.
- Axios para o cliente HTTP e interceptadores de autenticacao.
- TanStack Query para cache, atualizacao, invalidacao e polling dos dados remotos.
- React Hook Form com Zod para formularios e validacao.
- `jwt-decode` apenas para obter `login`, `role` e expiracao na interface. A autorizacao real continuara sendo feita pelo backend.
- Vitest e React Testing Library para testes de unidade e integracao.
- Playwright para os fluxos essenciais no navegador.

## 4. Configuracao de acesso a API

Usar a variavel:

```env
VITE_API_BASE_URL=/api
```

Durante o desenvolvimento, configurar o proxy do Vite para encaminhar `/api` ao backend, por exemplo `http://172.16.0.2:8000`. Isso evita bloqueio de CORS sem introduzir o Apache nesta etapa. O destino deve vir de uma segunda variavel de ambiente usada apenas pelo `vite.config.ts`.

Quando o Apache for integrado, o build continuara usando `/api`, sem alteracao nos servicos da aplicacao.

## 5. Contrato da API a ser implementado no frontend

### Autenticacao

| Acao | Metodo e rota | Corpo | Resposta relevante |
| --- | --- | --- | --- |
| Login | `POST /api/oauth/token` | `application/x-www-form-urlencoded` com `username` e `password` | `access_token`, `token_type` |

O token deve ser enviado nas demais chamadas como `Authorization: Bearer <token>`. Nesta versao, ele sera persistido em `localStorage` para sobreviver a recargas. O frontend deve remover tokens expirados ou rejeitados com `401`.

### Canais e sessoes

| Acao | Metodo e rota | Resposta relevante |
| --- | --- | --- |
| Listar canais | `GET /api/canais` | `id`, `number`, `name`, `description`, `status`, `viewer_count` |
| Detalhar canal | `GET /api/canais/{id}` | Dados do canal e objeto `video` opcional |
| Entrar no canal | `POST /api/canais/{id}/entrar` | `session_id`, `profile`, `multicast_address`, `port`, `playlist_url` |
| Baixar playlist | `GET /api/sessoes/{session_id}/playlist.m3u` | Arquivo `audio/x-mpegurl` |
| Manter sessao | `POST /api/sessoes/{session_id}/heartbeat` | `{ "status": "ok" }` |
| Sair da sessao | `POST /api/sessoes/{session_id}/sair` | `204 No Content` |

A playlist nao deve ser buscada em `/channels/{id}/playlist`. O frontend primeiro cria a sessao com `entrar` e depois usa o `playlist_url` retornado.

### Administracao

| Acao | Metodo e rota | Observacao |
| --- | --- | --- |
| Dashboard | `GET /api/admin/dashboard` | Fonte unica da telemetria |
| Criar canal | `POST /api/admin/canais` | Corpo JSON `ChannelPayload` |
| Editar canal | `PUT /api/admin/canais/{id}` | Corpo completo `ChannelPayload` |
| Remover canal | `DELETE /api/admin/canais/{id}` | Retorna `204` |
| Criar video | `POST /api/admin/videos` | Corpo JSON com caminhos HD e LD |
| Editar video | `PUT /api/admin/videos/{id}` | Corpo completo `VideoPayload` |
| Remover video | `DELETE /api/admin/videos/{id}` | Retorna `204` |
| Ler metadados | `POST /api/admin/videos/{id}/metadata` | Executa `ffprobe` sobre `hd_path` |

Nao existe `/api/admin/telemetry`. O dashboard retorna `active_users`, `active_channels`, `vlc_pids`, `wan_active_channel`, `active_streams` e `active_multicast_flows`.

## 6. Estrutura sugerida

```text
frontend/
  src/
    app/
      router.tsx
      query-client.ts
    api/
      client.ts
      auth.ts
      channels.ts
      sessions.ts
      admin.ts
      types.ts
    auth/
      AuthProvider.tsx
      ProtectedRoute.tsx
      AdminRoute.tsx
      token.ts
    components/
      AppShell.tsx
      ChannelCard.tsx
      ChannelGrid.tsx
      EmptyState.tsx
      ErrorNotice.tsx
      StatusBadge.tsx
    features/
      player/
        SessionPanel.tsx
        useChannelSession.ts
      admin/
        Dashboard.tsx
        ChannelForm.tsx
        VideoForm.tsx
        StreamsTable.tsx
    pages/
      LoginPage.tsx
      ChannelsPage.tsx
      ChannelPage.tsx
      AdminPage.tsx
      NotFoundPage.tsx
    test/
  .env.example
  package.json
  vite.config.ts
```

## 7. Modelos TypeScript principais

Criar tipos que preservem os nomes enviados pelo backend, sem conversoes silenciosas como `viewers` no lugar de `viewer_count`.

```ts
type UserRole = "admin" | "client";
type ClientProfile = "LAN" | "WAN115K";

interface ChannelSummary {
  id: number;
  number: number;
  name: string;
  description: string | null;
  status: string;
  viewer_count: number;
}

interface SessionDecision {
  session_id: number;
  profile: ClientProfile;
  multicast_address: string;
  port: number;
  playlist_url: string;
}

interface AdminDashboard {
  active_users: number;
  active_channels: number[];
  vlc_pids: number[];
  wan_active_channel: number | null;
  active_streams: ActiveStream[];
  active_multicast_flows: MulticastFlow[];
}
```

O valor de `status` deve ser tratado como string vinda da API. Inicialmente, `active` sera apresentado como "Ativo"; valores desconhecidos devem continuar visiveis em vez de serem descartados.

## 8. Fluxos de interface

### Login e sessao de usuario

1. Enviar as credenciais com `URLSearchParams`, nao JSON.
2. Persistir o JWT e decodificar os dados necessarios para navegacao.
3. Redirecionar clientes para `/canais` e administradores para `/admin` ou `/canais`, conforme a ultima rota valida.
4. Em qualquer `401`, limpar autenticacao, interromper heartbeat e voltar ao login.
5. Em `403`, manter a sessao e mostrar falta de permissao.

### Entrada e reproducao de canal

1. Ao selecionar "Assistir", encerrar uma sessao anterior antes de entrar em outro canal.
2. Executar `POST /api/canais/{id}/entrar`.
3. Exibir o perfil e o endereco multicast retornados pelo backend.
4. Buscar `playlist_url` como `Blob`, usando o cliente autenticado.
5. Criar uma URL temporaria e disparar o download do arquivo `.m3u`; depois revogar a URL.
6. Informar que a reproducao ocorre no VLC Client. O navegador nao consegue garantir a abertura automatica do aplicativo nativo.
7. Iniciar heartbeat a cada 20 segundos enquanto a sessao estiver ativa.
8. Ao sair, trocar de canal ou fazer logout, chamar `/sair`, cancelar o timer e invalidar a lista de canais.
9. Em fechamento ou recarga da pagina, tentar `/sair` com `fetch(..., { keepalive: true })`. Essa chamada e apenas uma protecao adicional e pode falhar em encerramentos abruptos.

### Conflito WAN115K

Ao receber `409`, ler `error.response.data.detail.active_channel` e informar que a WAN ja transmite aquele canal. Oferecer retorno a lista; se o canal ativo estiver cadastrado, tambem oferecer a acao de assisti-lo.

### Painel administrativo

- Atualizar `/api/admin/dashboard` por polling a cada 5 segundos enquanto a pagina estiver visivel.
- Mostrar usuarios ativos, canais ativos, canal WAN, PIDs do VLC e fluxos multicast.
- Usar tabelas para fluxos e cadastros; formularios devem abrir em painel lateral ou modal.
- Confirmar exclusoes e invalidar as consultas relacionadas apos sucesso.
- O formulario de video deve solicitar `hd_path` e `ld_path`; nao deve apresentar um seletor de upload inexistente.
- A acao "Ler metadados" deve ficar disponivel somente depois que o video possuir um `id` salvo.

## 9. Estados e tratamento de erros

- `401`: sessao expirada; limpar token e redirecionar ao login.
- `403`: operacao nao permitida para o perfil atual.
- `404`: recurso removido ou sessao inexistente; limpar estado local quando aplicavel.
- `409`: conflito de canal na WAN, com destaque ao canal ativo.
- Erro de rede: manter a pagina utilizavel e permitir nova tentativa.
- Playlist sem associacao de aplicativo: manter botao para baixar novamente.
- Canal sem video ou inativo: desabilitar "Assistir" quando essa condicao for conhecida pelo detalhe do canal.
- Operacoes destrutivas e formularios: apresentar estado de envio e impedir duplo clique.

## 10. Fases de implementacao

### Fase 1 - Fundacao

- Criar o projeto Vite React/TypeScript em `frontend/`.
- Configurar Tailwind, lint, formatacao, testes e variaveis de ambiente.
- Criar o cliente Axios, tipos da API e tratamento comum de erros.
- Configurar proxy de desenvolvimento do Vite.

### Fase 2 - Autenticacao

- Implementar login form-urlencoded.
- Criar `AuthProvider`, persistencia, expiracao e logout.
- Criar protecao de rotas por autenticacao e papel.
- Testar login valido, credenciais invalidas, token expirado e `403`.

### Fase 3 - Experiencia do cliente

- Implementar listagem e detalhe de canais.
- Implementar entrada, download autenticado da playlist e saida.
- Implementar heartbeat e troca segura de canal.
- Implementar conflito WAN e atualizacao da contagem de espectadores.
- Validar o arquivo baixado no VLC Client em uma maquina LAN e uma WAN.

### Fase 4 - Administracao operacional

- Implementar dashboard usando `/api/admin/dashboard`.
- Implementar CRUD de canais.
- Implementar formulario de cadastro de video por caminhos HD/LD.
- Implementar leitura de metadados.
- Integrar selecao de video atual do canal apos a API fornecer listagem de videos.

### Fase 5 - Qualidade e demonstracao

- Cobrir os fluxos principais com Vitest e Playwright.
- Verificar responsividade nas resolucoes dos clientes da demonstracao.
- Testar navegacao por teclado, foco, rotulos e contraste.
- Executar o roteiro LAN/WAN com dois clientes simultaneos.
- Gerar build e documentar execucao do frontend.

## 11. Testes de aceitacao

1. Cliente autentica e visualiza `viewer_count` para todos os canais.
2. Cliente LAN entra em um canal, baixa uma playlist `239.10.*` e envia heartbeat.
3. Cliente WAN entra em um canal e baixa uma playlist `239.20.*`.
4. Segundo cliente WAN recebe `409` ao tentar outro canal e consegue compartilhar o canal ativo.
5. Troca de canal encerra a sessao anterior antes de criar a nova.
6. Logout tenta encerrar a sessao ativa e remove o JWT.
7. Cliente comum nao acessa as telas administrativas.
8. Administrador visualiza todos os campos reais de `/api/admin/dashboard`.
9. Administrador cria, edita e remove canal.
10. Administrador cadastra caminhos HD/LD e solicita metadados de um video.
11. Respostas `401`, `403`, `404`, `409` e falhas de rede possuem mensagens e recuperacao adequadas.

## 12. Dependencias e lacunas do backend

Estas lacunas nao impedem o inicio do frontend, mas limitam a conclusao de algumas telas:

- Adicionar `GET /api/admin/videos` para listar o catalogo de videos. O repositorio ja possui `list_videos()`, mas a rota nao foi exposta. Sem ela, o frontend nao consegue reconstruir a lista apos recarregar nem oferecer uma selecao confiavel em `current_video_id`.
- Definir se o backend deve recusar explicitamente a entrada em canais inativos ou sem video. Hoje essa validacao nao esta expressa no contrato de listagem.
- Implementar expiracao automatica de sessoes sem heartbeat. O frontend fara a saida explicita e uma tentativa no fechamento, mas nao consegue garantir limpeza quando o navegador ou a maquina encerra abruptamente.
- Se upload e transcodificacao fizerem parte da entrega final, criar endpoints proprios no backend. O contrato atual aceita apenas caminhos de arquivos ja presentes no Host S e executa somente `ffprobe`.

## 13. Fora do escopo desta etapa

- Configuracao do Apache, HTTPS e proxy reverso em R1.
- Implementacao de um provedor OIDC externo; o backend atual usa login local e JWT.
- Reproducao de UDP multicast dentro do navegador.
- Upload de midia pelo navegador.
- Conversao automatica com `ffmpeg`.
- Alteracoes nas regras de multicast, controle da WAN ou ciclo de vida do `cvlc`.

## 14. Criterio de conclusao

O frontend estara pronto para integracao quando os testes de aceitacao aplicaveis passarem, o build for reproduzivel, os quatro clientes conseguirem acessar a interface e os fluxos LAN/WAN funcionarem com o VLC. A administracao completa de videos depende da exposicao de `GET /api/admin/videos`; upload e conversao permanecem uma evolucao separada do contrato.
