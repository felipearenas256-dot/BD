#!/usr/bin/env bash
# Practica 5 - Panel web (interfaz grafica) dentro de GitHub Codespaces
# Uso:  bash ver_tablas.sh
set -e
cd "$(dirname "$0")"

echo "== 1. Comprobando MySQL =="
if ! command -v mysqld >/dev/null 2>&1; then
  echo "   MySQL no esta instalado: ejecutando ejecutar_p5.sh primero..."
  bash ejecutar_p5.sh >/dev/null
fi
sudo mkdir -p /var/run/mysqld && sudo chown mysql:mysql /var/run/mysqld && sudo chmod 755 /var/run/mysqld
if ! sudo mysqladmin ping >/dev/null 2>&1; then
  sudo service mysql start >/dev/null 2>&1 || (sudo mysqld_safe --user=mysql >/dev/null 2>&1 &)
  for i in $(seq 1 60); do sudo mysqladmin ping >/dev/null 2>&1 && break; sleep 1; done
fi
sudo mysqladmin ping >/dev/null 2>&1 || { echo "!! MySQL no arranco. Corre: bash ejecutar_p5.sh"; exit 1; }
# Por si es la primera vez: root con la contrasena de la practica
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'RootLab_P4_2026!';" 2>/dev/null || true

echo "== 2. Preparando el panel (PHP con soporte MySQL) =="
# Codespaces trae su propio PHP SIN extension MySQL: se usa SIEMPRE /usr/bin/php
PHP=/usr/bin/php
if [ ! -x "$PHP" ] || ! "$PHP" -m | grep -qi mysqli; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq php-cli php-mysql >/dev/null
fi
if [ ! -s panel/adminer.php ]; then
  curl -sSL -o panel/adminer.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php || true
fi
# Libera el puerto 8080 si quedo ocupado por un panel anterior
if command -v fuser >/dev/null 2>&1; then sudo fuser -k 8080/tcp >/dev/null 2>&1 || true; fi

echo
echo "=============================================================="
echo "  Panel de la Practica 5 listo en el PUERTO 8080"
echo "  -> Haz clic en 'Open in Browser'"
echo "     (o pestana PORTS -> 8080 -> icono del globo)"
echo "  No pide usuario ni contrasena."
echo "  Para detenerlo: Ctrl + C"
echo "=============================================================="
exec "$PHP" -S 0.0.0.0:8080 -t panel
