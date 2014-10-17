#!/bin/sh

STRATEGY_NAME=""

case $1 in
    "random")
        STRATEGY_NAME="/localhost/nfd/strategy/random-load-balancer"
        ;;
    "weighted")
        STRATEGY_NAME="/localhost/nfd/strategy/weighted-load-balancer"
        ;;
    *)
        echo "Invalid forwarding strategy $1, exiting"
        exit 1
        ;;
    esac

source ./ndn-tutorial-config.sh

# Restart NFD on each node. This will clear the content store
# and reset routing.
for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    ssh -t -i ${KEY} -p ${PORT} ${USERNAME}@${HOST} "nfd-stop; sleep 2; nfd-start"
done

sleep 2

# Reconfigure routing for forwarding strategy scenarios.
for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    ssh -t -i ${KEY} -p ${PORT} ${USERNAME}@${HOST} "sh /usr/local/bin/setup-strategy-remote.sh $STRATEGY_NAME"
done

