#!/usr/bin/env bash
# Practica 5 - Interfaz grafica (tipo MySQL Workbench) dentro de GitHub Codespaces
# Uso:  bash ver_tablas.sh      (antes: bash ejecutar_p5.sh)
set -e
cd "$(dirname "$0")"

echo "== 1. Comprobando MySQL =="
sudo mkdir -p /var/run/mysqld && sudo chown mysql:mysql /var/run/mysqld && sudo chmod 755 /var/run/mysqld
if ! sudo mysqladmin ping >/dev/null 2>&1; then
  sudo service mysql start >/dev/null 2>&1 || (sudo mysqld_safe --user=mysql >/dev/null 2>&1 &)
  for i in $(seq 1 60); do sudo mysqladmin ping >/dev/null 2>&1 && break; sleep 1; done
fi
sudo mysqladmin ping >/dev/null 2>&1 || { echo "!! MySQL no esta encendido. Corre primero: bash ejecutar_p5.sh"; exit 1; }

echo "== 2. Instalando PHP con soporte MySQL y Adminer =="
# Codespaces trae su propio PHP SIN extension MySQL ("No hay extension"):
# por eso se usa SIEMPRE el PHP de Ubuntu en /usr/bin/php
PHP=/usr/bin/php
if [ ! -x "$PHP" ] || ! "$PHP" -m | grep -qi mysqli; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq php-cli php-mysql >/dev/null
fi
mkdir -p adminer
if [ ! -s adminer/adminer.php ]; then
  curl -sSL -o adminer/adminer.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php
fi
# Pagina de entrada: abre Adminer en ingles (evita que en espanol salgan numeros en vez de textos)
cat > adminer/index.php <<'PHP'
<?php
if (!isset($_GET['lang']) && !isset($_COOKIE['adminer_lang'])) {
  header('Location: ?lang=en&server=127.0.0.1&username=root&db=universidad_umb'); exit;
}
include __DIR__ . '/adminer.php';
PHP

# Cierra un Adminer anterior que siga ocupando el puerto 8080
pkill -f "php -S 0.0.0.0:8080" 2>/dev/null || true

echo
echo "=============================================================="
echo " Adminer listo en el PUERTO 8080"
echo " -> Codespaces mostrara 'Open in Browser': haz clic."
echo "    (o pestana PORTS -> 8080 -> icono del globo)"
echo
echo "   Servidor:   127.0.0.1        (ya viene escrito)"
echo "   Usuario:    root             (ya viene escrito)"
echo "   Contrasena: RootLab_P4_2026!"
echo "   Base:       universidad_umb  (ya viene escrita)"
echo
echo " Para detenerlo: Ctrl + C"
echo "=============================================================="
exec "$PHP" -S 0.0.0.0:8080 -t adminer
