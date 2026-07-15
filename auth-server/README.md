# Servidor Local de Autenticacao - Keycloak

Esta pasta define um provedor OAuth2/OpenID Connect local para a Mini-IPTV.

O Keycloak substitui a autenticacao propria do backend. O fluxo passa a ser:

```text
Frontend -> Keycloak -> JWT -> Backend FastAPI
```

## Como subir

Requisitos:

- Docker ou Podman com suporte a Compose.

Na raiz do repositorio:

```bash
cd auth-server
docker compose up -d
```

O Keycloak fica disponivel em:

```text
http://127.0.0.1:8080
```

Console administrativo:

```text
http://127.0.0.1:8080/admin
```

Credenciais do administrador do Keycloak:

```text
admin / admin
```

## Realm importado

O arquivo `realm-mini-iptv.json` cria:

- Realm: `mini-iptv`
- Client publico: `mini-iptv-frontend`
- Roles: `admin`, `client`
- Usuarios:
  - `admin / admin123`
  - `cliente1 / cliente123`
  - `cliente2 / cliente123`

## URLs OIDC importantes

Issuer:

```text
http://127.0.0.1:8080/realms/mini-iptv
```

JWKS:

```text
http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/certs
```

Authorization endpoint:

```text
http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/auth
```

Token endpoint:

```text
http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/token
```

## Variaveis do backend

```env
OIDC_ISSUER_URL=http://127.0.0.1:8080/realms/mini-iptv
OIDC_JWKS_URL=http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/certs
OIDC_AUDIENCE=mini-iptv-frontend
```

## Variaveis do frontend

```env
VITE_OIDC_AUTHORITY=http://127.0.0.1:8080/realms/mini-iptv
VITE_OIDC_CLIENT_ID=mini-iptv-frontend
VITE_OIDC_REDIRECT_URI=http://localhost:5173/auth/callback
VITE_OIDC_POST_LOGOUT_REDIRECT_URI=http://localhost:5173/login
```

## Observacao sobre o proxy reverso

Em desenvolvimento, o Keycloak pode ser acessado diretamente em `127.0.0.1:8080`.

Na topologia final, o Apache/R1 pode expor o Keycloak por um caminho ou host dedicado, por exemplo:

```text
https://r1.example/auth
```

Nesse caso, ajuste as URLs de issuer/authority e os redirects permitidos no realm.
