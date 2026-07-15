# Plano de Implementacao - Autenticacao Local com Keycloak/OIDC

## Objetivo

Migrar a autenticacao da Mini-IPTV para um servidor local OAuth2/OpenID Connect, mantendo a aplicacao conforme a especificacao do projeto: usuarios fazem login e senha em um provedor OIDC, recebem um JWT e usam esse token nas chamadas REST para o backend.

O servidor escolhido e o Keycloak, executado localmente via Docker. Ele pode rodar no Host S durante desenvolvimento ou ser exposto pelo R1/Apache na topologia final.

## Arquitetura alvo

```text
Frontend React
  -> redireciona login para Keycloak
  -> recebe access_token JWT
  -> chama /api com Authorization: Bearer <token>

Keycloak local
  -> realm mini-iptv
  -> client publico mini-iptv-frontend
  -> roles admin e client
  -> usuarios admin, cliente1 e cliente2

Backend FastAPI
  -> valida assinatura do JWT pelo JWKS do Keycloak
  -> valida issuer e audience/azp
  -> mapeia preferred_username para usuario local
  -> aplica autorizacao por role
```

## Fases

1. Criar `auth-server/` com Docker Compose, realm export e README.
2. Alterar backend para deixar de emitir JWT proprio como fluxo principal.
3. Validar tokens OIDC via `issuer`, `jwks_uri`, `aud`/`azp` e roles.
4. Adaptar testes do backend para gerar tokens OIDC de teste assinados com RSA.
5. Alterar frontend para usar Authorization Code + PKCE via `oidc-client-ts`.
6. Atualizar testes do frontend para refletir o novo provedor de autenticacao.
7. Documentar execucao local e variaveis de ambiente.

## Decisoes

- O endpoint antigo `POST /api/oauth/token` deixa de ser usado pelo frontend.
- O backend continua com usuarios seed locais para relacionar sessoes, mas senha e login passam a ser responsabilidade do Keycloak.
- As roles validas ficam em `realm_access.roles`: `admin` e `client`.
- O frontend usa `VITE_OIDC_AUTHORITY`, `VITE_OIDC_CLIENT_ID` e `VITE_OIDC_REDIRECT_URI`.
- O proxy reverso Apache pode expor tanto `/api` quanto o Keycloak, mas isso fica como etapa de infraestrutura.

## Criterios de aceite

- Cliente sem Bearer token recebe `401`.
- Token OIDC valido de `cliente1` acessa canais.
- Token OIDC com role `client` recebe `403` em rotas admin.
- Token OIDC com role `admin` acessa dashboard e CRUD.
- Token com issuer/audience incorretos e rejeitado.
- Frontend nao envia senha para o backend.
- Login/logout sao iniciados contra o Keycloak.
