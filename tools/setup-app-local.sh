#!/bin/sh

source ./ndn-tutorial-config.sh

# Restart NFD on each node. This will clear the content store
# and reset routing.

for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    ssh -t -i ${KEY} -p ${PORT}  ${USERNAME}@${HOST} "nfd-stop; sleep 2; nfd-start"
done

sleep 2

# Reconfigure routing for application scenarios.

for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    ssh -t -i ${KEY} -p ${PORT} ${USERNAME}@${HOST} "sh /usr/local/bin/setup-app-remote.sh"
done

