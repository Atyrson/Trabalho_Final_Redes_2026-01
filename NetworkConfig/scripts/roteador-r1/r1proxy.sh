#!/bin/bash
#
# Configuracao do Proxy Reverso / API Gateway (Apache HTTPD) no R1.
# Termina TLS (HTTPS autoassinado), serve o frontend e encaminha /api/ ao backend no host S.
#
# Uso: sudo ./r1proxy.sh [BACKEND_HOST] [BACKEND_PORT]   (padrao 172.16.0.2 8000)
#
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[ERRO] Este script precisa ser executado como ROOT (use sudo)." >&2
    exit 1
fi

BACKEND_HOST="${1:-${BACKEND_HOST:-172.16.0.2}}"
BACKEND_PORT="${2:-${BACKEND_PORT:-8000}}"

DOCROOT="/var/www/mini-iptv"
TLS_DIR="/etc/ssl/mini-iptv"
CONF_SRC="$(dirname "$0")/../../../backend/deploy/apache-mini-iptv.conf"
CONF_DST="/etc/apache2/sites-available/mini-iptv.conf"

echo "[R1] Backend alvo: http://${BACKEND_HOST}:${BACKEND_PORT}/api/"

echo "[R1] Instalando Apache..."
apt-get update -qq
apt-get install -y apache2 >/dev/null

echo "[R1] Habilitando modulos (ssl proxy proxy_http headers rewrite)..."
a2enmod ssl proxy proxy_http headers rewrite >/dev/null

echo "[R1] Gerando certificado TLS autoassinado (se ainda nao existir)..."
mkdir -p "$TLS_DIR"
if [ ! -f "$TLS_DIR/r1.crt" ]; then
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
        -keyout "$TLS_DIR/r1.key" -out "$TLS_DIR/r1.crt" \
        -subj "/CN=mini-iptv.r1.local"
    chmod 600 "$TLS_DIR/r1.key"
else
    echo "[R1] Certificado ja existe em $TLS_DIR. Mantido."
fi

echo "[R1] Preparando DocumentRoot ($DOCROOT)..."
mkdir -p "$DOCROOT"
if [ ! -f "$DOCROOT/index.html" ]; then
    # Placeholder ate o build do frontend (npm run build) ser copiado para ca.
    echo "<h1>Mini-IPTV: copie aqui o build do frontend.</h1>" > "$DOCROOT/index.html"
fi

echo "[R1] Instalando o vhost e ajustando o backend..."
install -m 644 "$CONF_SRC" "$CONF_DST"
sed -i "s|^Define BACKEND_HOST .*|Define BACKEND_HOST ${BACKEND_HOST}|" "$CONF_DST"
sed -i "s|^Define BACKEND_PORT .*|Define BACKEND_PORT ${BACKEND_PORT}|" "$CONF_DST"

echo "[R1] Ativando site e desativando o default..."
a2ensite mini-iptv.conf >/dev/null
a2dissite 000-default.conf >/dev/null 2>&1 || true

echo "[R1] Validando configuracao..."
apache2ctl configtest

echo "[R1] Reiniciando Apache..."
systemctl restart apache2

echo
echo "=== Proxy reverso ativo ==="
echo "  Frontend : https://r1.miniiptv.lan/            (R1 = 172.16.0.1)"
echo "  API      : https://r1.miniiptv.lan/api/  ->  http://${BACKEND_HOST}:${BACKEND_PORT}/api/"
echo "  (certificado autoassinado: o navegador exibira aviso na primeira visita)"
