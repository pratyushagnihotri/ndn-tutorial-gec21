#!/bin/sh

source ./ndn-tutorial-config.sh

scp -i $KEY -P `echo $UCLA_1 | cut -d ':' -f2` ../solutions/hello_consumer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_1 | cut -d ':' -f2` ../solutions/hello_ext_consumer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_2 | cut -d ':' -f2` ../solutions/hello_ext_consumer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_2 | cut -d ':' -f2` ../solutions/hello_consumer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_2 | cut -d ':' -f2` producer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_1 | cut -d ':' -f2` producer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $CSU_1 | cut -d ':' -f2` consumer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $CSU_1 | cut -d ':' -f2` ../solutions/hello_producer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $CSU_1 | cut -d ':' -f2` ../solutions/hello_ext_producer.py $USERNAME@$GENI_HOST:~/
scp -i $KEY -P `echo $UCLA_HUB | cut -d ':' -f2` ../solutions/*.{cpp,hpp} $USERNAME@$GENI_HOST:~/
