#!/bin/sh

cd /shared-location

echo "secret" | /usr/bin/kinit admin/admin@kerberos.gomesh.com 
cat /tmp/krb5cc_0 | base64 > /shared-location/cache.txt
cp /etc/krb5.conf /shared-location/
echo `date` >> /shared-location/last_generated.txt
