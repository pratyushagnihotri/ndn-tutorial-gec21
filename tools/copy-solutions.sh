#!/bin/sh

source ./ndn-tutorial-config.sh

scp -P `echo $UCLA_1 | cut -d ':' -f2` ../solutions/hello_consumer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_1 | cut -d ':' -f2` ../solutions/hello_ext_consumer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_2 | cut -d ':' -f2` ../solutions/hello_ext_consumer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_2 | cut -d ':' -f2` ../solutions/hello_consumer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_2 | cut -d ':' -f2` producer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_1 | cut -d ':' -f2` producer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $CSU_1 | cut -d ':' -f2` consumer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $CSU_1 | cut -d ':' -f2` ../solutions/hello_producer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $CSU_1 | cut -d ':' -f2` ../solutions/hello_ext_producer.py $USERNAME@$GENI_HOST:~/
scp -P `echo $UCLA_HUB | cut -d ':' -f2` ../solutions/*.{cpp,hpp} $USERNAME@$GENI_HOST:~/
