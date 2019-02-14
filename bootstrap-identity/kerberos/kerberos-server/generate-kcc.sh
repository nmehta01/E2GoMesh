#!/bin/sh

cd /shared-location

while true;do
    echo "secret" | /usr/bin/kinit admin/admin@kerberos.gomesh.com -c /shared-location/cache.txt
    echo `date` >> /shared-location/last_generated.txt
    sleep 10m 
done
