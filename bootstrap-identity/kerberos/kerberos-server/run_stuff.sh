#!/bin/sh


nohup /docker-entrypoint.sh &

sleep 20s

nohup /usr/sbin/krb5kdc -n &
nohup /usr/sbin/kadmind -nofork &

sleep 30s

while true
do
   nohup /generate-kcc.sh &
   sleep 10m
done
