#!/bin/bash
# Prova online completa: finto Firebase + due istanze di Godot (host e ospite) che giocano con l'IA.
# Le due impronte finali devono essere uguali. Uso: GODOT=/percorso/godot tests/prova_online.sh
cd "$(dirname "$0")/.."
G=${GODOT:-godot}
python3 tests/firebase_mock.py 8765 > /tmp/mock.log 2>&1 &
MOCK=$!
sleep 1
export FR_DB_URL=http://127.0.0.1:8765/db FR_AUTH_URL=http://127.0.0.1:8765/signup FR_REFRESH_URL=http://127.0.0.1:8765/refresh
rm -f /tmp/is_codice /tmp/is_host.cfg /tmp/is_guest.cfg
IS_RUOLO=host IS_CODICE=/tmp/is_codice FR_SESSION=/tmp/is_host.cfg timeout 600 $G --headless --path . -s res://tests/online_auto.gd > /tmp/is_host.log 2>&1 &
H=$!
IS_RUOLO=guest IS_CODICE=/tmp/is_codice FR_SESSION=/tmp/is_guest.cfg timeout 600 $G --headless --path . -s res://tests/online_auto.gd > /tmp/is_guest.log 2>&1 &
O=$!
wait $H $O
kill $MOCK
grep "IS \|ERROR" /tmp/is_host.log /tmp/is_guest.log
