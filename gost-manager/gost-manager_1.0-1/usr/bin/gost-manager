#!/bin/bash

# GOST Proxy Manager for Ubuntu
# Requires: ss, lsof, curl

clear

echo "====================================="
echo " GOST SOCKS5 Proxy Manager"
echo " by Daniel Murimi Njiraini"
echo "====================================="
echo

read -p "Enter proxy port to check [8080]: " PORT
PORT=${PORT:-8080}

echo
echo "[+] Checking port $PORT..."
echo

PIDS=$(sudo lsof -t -i :"$PORT")

if [ -z "$PIDS" ]; then
    echo "No process found using port $PORT."
else
    echo "Processes using port $PORT:"
    sudo lsof -i :"$PORT"

    echo
    read -p "Kill these processes? (y/n): " CONFIRM

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        for PID in $PIDS; do
            echo "Killing PID $PID..."
            sudo kill -9 "$PID"
        done
        echo "Processes terminated."
    else
        echo "Skipping kill operation."
    fi
fi


echo
echo "[+] Checking if port is free..."

if ss -ltn | grep -q ":$PORT "; then
    echo "WARNING: Port $PORT is still occupied."
    ss -ltnp | grep ":$PORT "
    exit 1
else
    echo "Port $PORT is available."
fi


echo
echo "====================================="
echo " Start GOST"
echo "====================================="
echo

echo "Example:"
echo "gost -L=socks5://127.0.0.1:$PORT -F=socks5://"username:password@IP:Port"
echo

read -p "Paste GOST initiator command: " GOSTCMD

echo
echo "Starting GOST..."
echo

start_gost() {
    nohup bash -c "$GOSTCMD" > gost.log 2>&1 &
    sleep 3
}

kill_gost() {
    sudo pkill -9 -x gost 2>/dev/null
    sleep 1
}

test_proxy() {
    curl --silent --show-error --connect-timeout 10 --socks5-hostname 127.0.0.1:$PORT https://ifconfig.me >/dev/null
}

kill_gost
start_gost

echo
echo "[+] Checking GOST listener..."
ss -ltnp | grep ":$PORT " || true

echo
read -p "Run SOCKS5 test? (y/n): " TEST

if [[ "$TEST" == "y" || "$TEST" == "Y" ]]; then
    echo
    echo "Testing proxy..."

    if test_proxy; then
        echo "SUCCESS: Proxy works."
    else
        echo "First attempt failed. Restarting GOST..."
        kill_gost
        start_gost

        if test_proxy; then
            echo "SUCCESS: Proxy works after restart."
        else
            echo "FAILED after second attempt."
            echo
            cat gost.log
        fi
    fi
fi


echo
echo "Finished."
