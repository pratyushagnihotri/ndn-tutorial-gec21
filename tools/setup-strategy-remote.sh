#!/bin/sh

HOST=`hostname | cut -d '.' -f1`
STRATEGY_NAME=$1

case $HOST in
    "ucla-1")
        echo "No action required for ucla-1"
        ;;
    "ucla-2")
        echo "No action required for ucla-2"
        ;;
    "ucla-hub")
        nfdc register /ucla udp4://10.0.0.2
        nfdc register /ucla udp4://10.0.0.3
        nfdc set-strategy /ucla $STRATEGY_NAME
        ;;
    "csu-1")
        nfdc register / udp4://10.0.20.1
        ;;
    "csu-hub")
        nfdc register /ucla udp4://10.0.10.1
        ;;
esac
