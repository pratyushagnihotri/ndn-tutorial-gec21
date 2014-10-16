#!/bin/sh

source ndn-tutorial-config.sh

for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    scp -i ${KEY} -P ${PORT} .remote-scripts/setup-app-remote.sh ${USERNAME}@${HOST}:~/
    scp -i ${KEY} -P ${PORT} .remote-scripts/setup-strategy-remote.sh ${USERNAME}@${HOST}:~/
    ssh -t -p ${PORT} ${USERNAME}@${HOST} "chmod +x setup-app-remote.sh setup-strategy-remote.sh; sudo mv setup-app-remote.sh setup-app-remote.sh /usr/local/bin;"
done
