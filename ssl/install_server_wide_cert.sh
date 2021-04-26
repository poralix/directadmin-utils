#!/bin/bash
# ============================================================================
#  This script is written to be used on a directadmin powered server and can
#  be used to do a quick installation of a SSL cert/key for server-wide usage
#  i.e. SSL cert used by default (on hostname) in Apache/Nginx, Exim/Dovecot.
# ============================================================================
#  IMPORTANT: Written and tested on CentOS 6.x, 7.x only
# ============================================================================
# Written by: Alex S Grebenschikov (support@porailx.com)
#  Copyright: 2015, 2017, 2021 Alex S Grebenschikov
#  Created at: Wed 28 Oct 2015 17:14:32 NOVT
#  Last modified: Tue Apr 27 00:33:34 +07 2021
#  Version: 0.3 $ Tue Apr 27 00:33:34 +07 2021
#           0.2 $ Thu Jun 29 09:36:58 +07 2017
#           0.1 $ Wed 28 Oct 2015 17:14:53 NOVT
# ============================================================================
#
 
# A LIST OF SERVICES YOU WANT A CERT TO BE INSTALLED FOR
SERVICES="directadmin apache nginx exim dovecot";
 
# ============================================================================
# DO NOT CHANGE ANYTHING BELLOW
# ============================================================================
 
BOLD="`tput -Txterm bold`";
RED="`tput -Txterm setaf 1`";
GREEN="`tput -Txterm setaf 2`";
RESET="`tput -Txterm sgr0`";
OPENSSL='/usr/bin/openssl';

do_restart()
{
    echo;
    echo "${BOLD}Restarting service $1${RESET}";
    if [ -x "/bin/systemctl" ] || [ -x "/usr/bin/systemctl" ]; 
    then
    {
        systemctl restart $1;
    }
    elif [ -x "/etc/init.d/$1" ];
    then
    {
        /etc/init.d/$1 restart;
    }
    else
    {
        echo "You need to restart $1 manually in order to changes to take effect!";
    }
    fi;
}
 
do_cert_exim_dovecot()
{
    echo "${BOLD}Installing cert/key for Exim and Dovecot${RESET}";
    COMBCERTTO="/etc/exim.cert";
    KEYTO="/etc/exim.key";
    cp -v ${PCERT} ${COMBCERTTO};
    cp -v ${PKEY} ${KEYTO};
    if [ -f "${PCACERT}" ];
    then
    {
        echo "" >> ${COMBCERTTO};
        cat ${PCACERT} >> ${COMBCERTTO};
    }
    fi;
    chmod -v 600  ${KEYTO} ${COMBCERTTO};
    chown -v mail ${KEYTO} ${COMBCERTTO};
    chgrp -v mail ${KEYTO} ${COMBCERTTO};
    do_restart exim;
    do_restart dovecot;
    echo;
}
 
do_cert_apache()
{
    echo "${BOLD}Installing cert/key for Apache${RESET}";
    CACERTTO="/etc/httpd/conf/ssl.crt/server.ca";
    CERTTO="/etc/httpd/conf/ssl.crt/server.crt";
    COMBCERTTO="/etc/httpd/conf/ssl.crt/server.crt.combined";
    KEYTO="/etc/httpd/conf/ssl.key/server.key";
    cp -v ${PCERT} ${CERTTO};
    cp -v ${PKEY} ${KEYTO};
    if [ -f "${PCACERT}" ];
    then
    {
        cp -v ${PCACERT} ${CACERTTO};
        cp -v ${PCERT} ${COMBCERTTO};
        echo "" >> ${COMBCERTTO};
        cat ${PCACERT} >> ${COMBCERTTO};
    }
    fi;
    chmod -v 600  ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chown -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chgrp -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    do_restart httpd;
    echo;
}
 
do_cert_nginx()
{
    echo "${BOLD}Installing cert/key for NGINX${RESET}";
    CACERTTO="/etc/nginx/ssl.crt/server.ca";
    CERTTO="/etc/nginx/ssl.crt/server.crt";
    COMBCERTTO="/etc/nginx/ssl.crt/server.crt.combined";
    KEYTO="/etc/nginx/ssl.key/server.key";
    cp -v ${PCERT} ${CERTTO};
    cp -v ${PKEY} ${KEYTO};
    if [ -f "${PCACERT}" ];
    then
    {
        cp -v ${PCACERT} ${CACERTTO};
        cp -v ${PCERT} ${COMBCERTTO};
        echo "" >> ${COMBCERTTO};
        cat ${PCACERT} >> ${COMBCERTTO};
    }
    fi;
    chmod -v 600  ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chown -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chgrp -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    do_restart nginx;
    echo;
}
 
do_cert_directadmin()
{
    echo "${BOLD}Installing cert/key for Directadmin${RESET}";
    CERTTO="/usr/local/directadmin/conf/cacert.pem";
    KEYTO="/usr/local/directadmin/conf/cakey.pem";
    CACERTTO="/usr/local/directadmin/conf/carootcert.pem";
    cp -v ${PCERT} ${CERTTO};
    cp -v ${PKEY} ${KEYTO};
    [ -f "${PCACERT}" ] && cp -v ${PCACERT} ${CACERTTO};
    chmod -v 600 ${CERTTO} ${KEYTO} ${CACERTTO};
    chown -v diradmin:diradmin ${CERTTO} ${KEYTO} ${CACERTTO};
    killall -9 directadmin
    do_restart directadmin;
    echo;
}
 
do_print_copyright()
{
    echo "==========================================================================";
    echo " ${BOLD}Written by Alex Grebenschikov (support@poralix.com), 2015,2017,2021${RESET}";
    echo "==========================================================================";
}
 
do_print_usage()
{
    echo "";
    echo "Usage: ${BOLD}${0} <PATH_TO_CERT> <PATH_TO_KEY> [<PATH_TO_CACERT>]${RESET}";
    echo "";
    echo "         ============================================================================";
    echo "          This script is written to be used on a directadmin powered server and can";
    echo "          be used to do a quick installation of a SSL cert/key for server-wide usage";
    echo "          i.e. SSL cert used by default (on hostname) in Apache/Nginx, Exim/Dovecot.";
    echo "         ============================================================================";
    echo "";
    echo "          PATH_TO_CERT    - a full or relative path to a CERT you want to install";
    echo "          PATH_TO_KEY     - a full or relative path to a KEY you want to install";
    echo "          PATH_TO_CACERT  - a full or relative path to a CACERT you want to install";
    echo "";
    echo "         ============================================================================";
    echo "";
    echo "          Copyright (c) 2015,2017,2021 Alex S Grebenschikov (support@poralix.com)";
    echo "";
    exit 1;
}
 
do_validate_cert()
{
    CCERT="$1";
    ${OPENSSL} x509 -noout -pubkey -in ${CCERT} >/dev/null 2>&1;
    RES=$?;
    echo "[INFO] Validating CERT ${BOLD}${CCERT}${RESET}";
    if [ "${RES}" -gt "0" ];
    then
    {
        echo "${RED}[ERROR]${RESET} File ${CCERT} is not a valid CERT";
        exit 1;
    }
    else
    {
        HCERT=$(${OPENSSL} x509 -noout -pubkey -in ${CCERT} 2>&1 | ${OPENSSL} md5 | cut -d\  -f2);
        echo "${GREEN}[OK]${RESET} The cert md5 hash: ${BOLD}${HCERT}${RESET}";
    }
    fi;
}
 
do_validate_key()
{
    CKEY="$1";
    ${OPENSSL} pkey -pubout -in ${CKEY} >/dev/null 2>&1;
    RES=$?;
    echo "[INFO] Validating CERT ${BOLD}${CKEY}${RESET}";
    if [ "${RES}" -gt "0" ];
    then
    {
        echo "${RED}[ERROR]${RESET} File ${CKEY} is not a valid KEY";
        exit 1;
    }
    else
    {
        HKEY=$(${OPENSSL} pkey -pubout -in ${CKEY} 2>&1 | ${OPENSSL} md5 | cut -d\  -f2);
        echo "${GREEN}[OK]${RESET} The key md5 hash: ${BOLD}${HKEY}${RESET}";
    }
    fi;
}
 
if [ -z "$1" ];
then
{
    do_print_usage;
}
else
{
    if [ -f "$1" ];
    then
    {
        PCERT="$1";
    }
    fi;
}
fi;
 
if [ -z "$2" ];
then
{
    do_print_usage;
}
else
{
    if [ -f "$2" ];
    then
    {
        PKEY="$2";
    }
    fi;
}
fi;
 
do_print_copyright;
do_validate_cert "${PCERT}";
do_validate_key "${PKEY}";
 
if [ "${HKEY}" == "${HCERT}" ];
then
{
    echo "${GREEN}[OK]${RESET} CERT and KEY match each other!";
}
else
{
    echo "${RED}[ERROR]${RESET} CERT and KEY do not match each other!";
    exit 1;
}
fi;
 
if [ -n "$3" ];
then
{
    if [ -f "$3" ];
    then
    {
        PCACERT="$3";
        echo "[INFO] You provided CACERT ${BOLD}${PCACERT}${RESET}";
        do_validate_cert ${PCACERT};
    }
    fi;
}
fi;
 
# DIRECTADMIN
c=`echo ${SERVICES} | grep -c directadmin`;
[ "$c" -eq "1" ] && do_cert_directadmin;
 
# APACHE
c=`echo ${SERVICES} | grep -c apache`;
[ "$c" -eq "1" ] && do_cert_apache;
 
# NGINX
c=`echo ${SERVICES} | grep -c apache`;
if [ "$c" -eq "1" ];
then
{
    is_nginx=`/usr/local/directadmin/directadmin c | grep ^nginx= | cut -d\= -f2`
    is_nginx_proxy=`/usr/local/directadmin/directadmin c | grep ^nginx_proxy= | cut -d\= -f2`
 
    if [ "${is_nginx}" -eq "1" ] || [ "${is_nginx_proxy}" -eq "1" ];
    then
    {
        echo "[INFO] NGINX is set in directadmin.conf";
        do_cert_nginx;
    }
    else
    {
        echo "[INFO] NGINX is not set in directadmin.conf";
        echo;
    }
    fi;
}
fi;
 
# EXIM
c=`echo ${SERVICES} | grep -c exim`;
if [ "$c" -eq "1" ];
then
{
    do_cert_exim_dovecot;
}
else
{
    c=`echo ${SERVICES} | grep -c dovecot`;
    [ "$c" -eq "1" ] && do_cert_exim_dovecot;
}
fi;
 
exit 0;
