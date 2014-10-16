#!/bin/sh

source ./ndn-tutorial-config.sh

for NODE in ${UCLA_HUB} ${UCLA_1} ${UCLA_2} ${CSU_HUB} ${CSU_1};
do
    HOST=`echo $NODE | cut -d ':' -f1`
    PORT=`echo $NODE | cut -d ':' -f2`

    echo ${NODE}

    scp -i ${KEY} -P ${PORT} setup-app-remote.sh ${USERNAME}@${HOST}:~/
    scp -i ${KEY} -P ${PORT} setup-strategy-remote.sh ${USERNAME}@${HOST}:~/
    ssh -t -p ${PORT} ${USERNAME}@${HOST} "chmod +x setup-app-remote.sh setup-strategy-remote.sh; sudo mv setup-app-remote.sh /usr/local/bin; sudo mv setup-strategy-remote.sh /usr/local/bin"
done
