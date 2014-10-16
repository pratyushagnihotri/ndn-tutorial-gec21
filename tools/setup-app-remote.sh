#!/bin/sh

HOST=`hostname | cut -d '.' -f1`

case $HOST in
    "ucla-1")
        nfdc register / udp4://10.0.0.1
        ;;
    "ucla-2")
        nfdc register / udp4://10.0.0.1
        ;;
    "ucla-hub")
        nfdc register /csu udp4://10.0.10.2
        ;;
    "csu-1")
        echo "No action required for csu-1"
        ;;
    "csu-hub")
        nfdc register /csu udp4://10.0.20.2
        ;;
esac
