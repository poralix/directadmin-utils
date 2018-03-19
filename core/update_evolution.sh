#!/bin/bash
#################################
# Update Evolution Demo Skin
# by Poralix
#################################

update_skin()
{
    DIR="/usr/local/directadmin/data/skins/evolution";
    [ -d "${DIR}" ] || mkdir -p "${DIR}";
    cd "${DIR}";
    wget -O evolution.tar.gz http://demo.directadmin.com/download/evolution.tar.gz;
    tar -xzf evolution.tar.gz;
    chown -R diradmin:diradmin "${DIR}";
}

update_binary()
{
    wget -O /root/updateda.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/core/updateda.sh;
    chmod 755 /root/updateda.sh;
    /root/updateda.sh beta;
    service directadmin restart;
}

if [ "$1" == "-v" ] || [ "$1" == "-V" ]; then
    update_binary;
    update_skin;
else
    update_binary >/dev/null 2>&1;
    update_skin >/dev/null 2>&1;
fi;

exit 0;
