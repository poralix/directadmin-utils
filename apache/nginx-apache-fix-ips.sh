#!/bin/bash
# ========================================================================
#
# A script to add all IPs from Directadmin config into Apache
# to address a bug with detecting a real IP in Apache behind Nginx
# A bug introduced since Apache 2.4.33
# It fails to read IPs from the file, as per instruction:
#   RemoteIPInternalProxyList /usr/local/directadmin/data/admin/ip.list
#
# ========================================================================
# Written by Alex S Grebenschikov # poralix.com (support@poralix.com)
# Created: Mon Mar 26 14:43:17 +07 2018
# Last modified: Mon Mar 26 14:43:17 +07 2018
#

RESTART_APACHE=0;

add_ip()
{
    local IP=$1;
    egrep -q "^RemoteIPInternalProxy.*${IP}(|\ )$" "/etc/httpd/conf/extra/httpd-nginx.conf";
    if [ "$?" -ne "0" ];
    then
        RESTART_APACHE=1;
        echo "[OK] Adding IP ${IP} into Apache's config";
        echo "RemoteIPInternalProxy ${IP}" >> "/etc/httpd/conf/extra/httpd-nginx.conf";
    else
        echo "[NOTICE] IP ${IP} already exists in Apache's config. Skipping...";
    fi;
}

if [ ! -e "/etc/httpd/conf/extra/httpd-nginx.conf" ]; then
    echo "Do you realy use NGINX-Apache?";
    exit 1;
fi;

if [ ! -e "/usr/local/directadmin/data/admin/ip.list" ]; then
    echo "Is that really a server with Directadmin?";
    exit 2;
fi;

for IP in `cat /usr/local/directadmin/data/admin/ip.list | sort | uniq`;
do
    add_ip ${IP};
done;

[ "${RESTART_APACHE}" == "1" ] && service httpd restart;

exit 0;
