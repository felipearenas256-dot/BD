#!/usr/bin/env bash
# Practica 5 - Procedimientos, Funciones, Cursores y Triggers
# Ejecuta todo en GitHub Codespaces.   Uso:  bash ejecutar_p5.sh
set -e
cd "$(dirname "$0")"
ROOTPW='RootLab_P4_2026!'

echo "== 1. Instalando MySQL (si hace falta) =="
if ! command -v mysqld >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mysql-server >/dev/null
fi

echo "== 2. Iniciando MySQL =="
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld
vivo(){ sudo mysqladmin ping >/dev/null 2>&1; }
if ! vivo; then
  sudo service mysql start >/dev/null 2>&1 || (sudo mysqld_safe --user=mysql >/dev/null 2>&1 &)
  for i in $(seq 1 60); do vivo && break; sleep 1; done
fi
if ! vivo; then
  echo "!! MySQL no pudo arrancar:"; sudo tail -n 25 /var/log/mysql/error.log; exit 1
fi
# Primera vez: root entra sin contrasena (auth_socket) -> se le asigna la de la practica
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$ROOTPW';" 2>/dev/null || true

echo "== 3. Ejecutando practica5.sql (Actividades 1 a 5) =="
echo "   (los 3 ERROR 1644 de la Actividad 5 son ESPERADOS: el trigger rechaza notas invalidas)"
mysql -h 127.0.0.1 -uroot -p"$ROOTPW" --default-character-set=utf8mb4 --force -t \
      < practica5.sql > salida_practica5.txt 2>&1 || true
grep -v "Using a password" salida_practica5.txt > salida.tmp && mv salida.tmp salida_practica5.txt
cat salida_practica5.txt

echo
echo "== TERMINADO -> resultados en salida_practica5.txt =="
echo "Entrar a MySQL:  mysql -h 127.0.0.1 -u root -p'$ROOTPW' universidad_umb"
