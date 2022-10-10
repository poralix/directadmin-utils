#!/bin/bash
# ============================================================================
#  This script is written to be used on a directadmin powered server and can
#  be used to do a quick installation of a SSL cert/key for server-wide usage
#  i.e. SSL cert used by default (on hostname) in Apache/Nginx, Exim/Dovecot.
# ============================================================================
#  IMPORTANT: Written and tested on CentOS 6.x, 7.x only
# ============================================================================
# Written by: Alex S Grebenschikov (support@porailx.com)
#  Copyright: 2015-2022 Alex S Grebenschikov
#  Created at: Wed 28 Oct 2015 17:14:32 NOVT
#  Last modified: Mon Oct 10 18:24:44 +07 2022
#  Version: 0.8 $ Mon Oct 10 18:24:44 +07 2022
#           0.7 $ Wed Aug 31 12:58:29 +07 2022
#           0.6 $ Wed May 26 13:14:23 +07 2021
#           0.5 $ Mon May 17 21:51:45 +07 2021
#           0.4 $ Tue Apr 27 18:40:46 +07 2021
#           0.3 $ Tue Apr 27 00:33:34 +07 2021
#           0.2 $ Thu Jun 29 09:36:58 +07 2017
#           0.1 $ Wed 28 Oct 2015 17:14:53 NOVT
# ============================================================================
#

# A LIST OF SERVICES YOU WANT A CERT TO BE INSTALLED FOR
SERVICES="";
SERVICES="${SERVICES} directadmin";
SERVICES="${SERVICES} apache";
SERVICES="${SERVICES} nginx";
SERVICES="${SERVICES} litespeed";
SERVICES="${SERVICES} openlitespeed";
SERVICES="${SERVICES} exim";
SERVICES="${SERVICES} dovecot";

# ============================================================================
# DO NOT CHANGE ANYTHING BELLOW
# ============================================================================

BOLD="$(tput -Txterm bold)";
RED="$(tput -Txterm setaf 1)";
GREEN="$(tput -Txterm setaf 2)";
RESET="$(tput -Txterm sgr0)";
OPENSSL='/usr/bin/openssl';

die()
{
    echo "$1";
    exit $2;
}

do_restart()
{
    echo;
    if [ -x "/bin/systemctl" ] || [ -x "/usr/bin/systemctl" ]; then
        echo "${GREEN}[OK]${RESET} ${BOLD}Restarting service $1${RESET}";
        systemctl restart $1;
    elif [ -x "/etc/init.d/$1" ]; then
        echo "${GREEN}[OK]${RESET} ${BOLD}Restarting service $1${RESET}";
        /etc/init.d/$1 restart;
    else
        echo "${RED}[WARNING]${RESET} You need to restart $1 manually in order to changes to take effect!";
    fi;
}

do_cert_exim_dovecot()
{
    echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for Exim and Dovecot${RESET}";
    COMBCERTTO="/etc/exim.cert";
    KEYTO="/etc/exim.key";
    cp -v ${PCERT} ${COMBCERTTO};
    cp -v ${PKEY} ${KEYTO};
    if [ -f "${PCACERT}" ]; then
        echo "" >> ${COMBCERTTO};
        cat ${PCACERT} >> ${COMBCERTTO};
    fi;
    chmod -v 600  ${KEYTO} ${COMBCERTTO};
    chown -v mail ${KEYTO} ${COMBCERTTO};
    chgrp -v mail ${KEYTO} ${COMBCERTTO};
    do_restart exim;
    do_restart dovecot;
    echo;
}

do_cert_httpd()
{
    CACERTTO="/etc/httpd/conf/ssl.crt/server.ca";
    CERTTO="/etc/httpd/conf/ssl.crt/server.crt";
    COMBCERTTO="/etc/httpd/conf/ssl.crt/server.crt.combined";
    KEYTO="/etc/httpd/conf/ssl.key/server.key";
    cp -v ${PCERT} ${CERTTO};
    cp -v ${PCERT} ${COMBCERTTO};
    cp -v ${PKEY}  ${KEYTO};
    if [ -f "${PCACERT}" ]; then
        cp -v ${PCACERT} ${CACERTTO};
        echo "" >> ${COMBCERTTO};
        cat ${PCACERT} >> ${COMBCERTTO};
    fi;
    chmod -v 600  ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chown -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
    chgrp -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
}

do_cert_openlitespeed()
{
    c=$(echo ${SERVICES} | grep -c "\ openlitespeed");
    if [ "${c}" -eq "0" ]; then
        echo "${RED}[WARNING]${RESET} ${BOLD}Skipping installation of cert/key for OpenLiteSpeed${RESET}";
    else
        echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for OpenLiteSpeed${RESET}";
        CACERTTO="/usr/local/lsws/ssl.crt/server.ca";
        CERTTO="/usr/local/lsws/ssl.crt/server.crt";
        COMBCERTTO="/usr/local/lsws//ssl.crt/server.crt.combined";
        KEYTO="/usr/local/lsws/ssl.key/server.key";
        cp -v ${PCERT} ${CERTTO};
        cp -v ${PCERT} ${COMBCERTTO};
        cp -v ${PKEY}  ${KEYTO};
        if [ -f "${PCACERT}" ]; then
            cp -v ${PCACERT} ${CACERTTO};
            echo "" >> ${COMBCERTTO};
            cat ${PCACERT} >> ${COMBCERTTO};
        fi;
        chmod -v 600  ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        chown -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        chgrp -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        do_cert_httpd;
        do_restart litespeed;
    fi;
    echo;
}

do_cert_litespeed()
{
    c=$(echo ${SERVICES} | grep -c "\ litespeed");
    if [ "${c}" -eq "0" ]; then
        echo "${RED}[WARNING]${RESET} ${BOLD}Skipping installation of cert/key for Litespeed${RESET}";
    else
        echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for Litespeed${RESET}";
        do_cert_httpd;
        do_restart litespeed;
    fi;
    echo;
}

do_cert_apache()
{
    c=$(echo ${SERVICES} | grep -c "\ apache");
    if [ "${c}" -eq "0" ]; then
        echo "${RED}[WARNING]${RESET} ${BOLD}Skipping installation of cert/key for Apache${RESET}";
    else
        echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for Apache${RESET}";
        do_cert_httpd;
        do_restart httpd;
    fi;
    echo;
}

do_cert_nginx()
{
    c=$(echo ${SERVICES} | grep -c "\ apache");
    if [ "${c}" -eq "0" ]; then
        echo "${RED}[WARNING]${RESET} ${BOLD}Skipping installation of cert/key for NGINX${RESET}";
    else
        echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for NGINX${RESET}";
        CACERTTO="/etc/nginx/ssl.crt/server.ca";
        CERTTO="/etc/nginx/ssl.crt/server.crt";
        COMBCERTTO="/etc/nginx/ssl.crt/server.crt.combined";
        KEYTO="/etc/nginx/ssl.key/server.key";
        cp -v ${PCERT} ${CERTTO};
        cp -v ${PCERT} ${COMBCERTTO};
        cp -v ${PKEY}  ${KEYTO};
        if [ -f "${PCACERT}" ]; then
            cp -v ${PCACERT} ${CACERTTO};
            echo "" >> ${COMBCERTTO};
            cat ${PCACERT} >> ${COMBCERTTO};
        fi;
        chmod -v 600  ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        chown -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        chgrp -v root ${CERTTO} ${KEYTO} ${CACERTTO} ${COMBCERTTO};
        do_restart nginx;
    fi;
    echo;
}

do_cert_directadmin()
{
    echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for Directadmin${RESET}";
    CERTTO="/usr/local/directadmin/conf/cacert.pem";
    KEYTO="/usr/local/directadmin/conf/cakey.pem";
    CACERTTO="";
    cp -v "${PCERT}" "${CERTTO}";
    cp -v "${PKEY}" "${KEYTO}";
    if [ -f "${PCACERT}" ]; then
        CACERTTO="/usr/local/directadmin/conf/carootcert.pem";
        cp -v "${PCACERT}" "${CACERTTO}";
    fi;
    chmod -v 600 ${CERTTO} ${KEYTO} ${CACERTTO};
    chown -v diradmin:diradmin ${CERTTO} ${KEYTO} ${CACERTTO};
    killall -9 directadmin;
    do_restart directadmin;
    echo;
}

do_cert_pureftpd()
{
    echo "${GREEN}[OK]${RESET} ${BOLD}Installing cert/key for PureFTPd${RESET}";
    COMBO_CERT_TO="/etc/pure-ftpd.pem";
    cat ${PCERT} ${PKEY} > ${COMBO_CERT_TO};
    [ -f "${PCACERT}" ] && cat ${PCACERT} >> ${COMBO_CERT_TO};
    chmod -v 600 ${COMBO_CERT_TO};
    chown -v 0:0 ${COMBO_CERT_TO};
    do_restart pure-ftpd;
    echo;
}

do_print_copyright()
{
    echo "==========================================================================";
    echo " ${BOLD}Written by Alex Grebenschikov (support@poralix.com), 2015-2022${RESET}";
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
    echo "          Copyright (c) 2015-2022 Alex S Grebenschikov (support@poralix.com)";
    echo "";
    exit 1;
}

do_validate_cert()
{
    CCERT="$1";
    ${OPENSSL} x509 -noout -pubkey -in ${CCERT} >/dev/null 2>&1;
    RES=$?;
    echo "[INFO] Validating CERT ${BOLD}${CCERT}${RESET}";
    if [ "${RES}" -gt "0" ]; then
        echo "${RED}[ERROR]${RESET} File ${CCERT} is not a valid CERT";
        exit 1;
    else
        HCERT=$(${OPENSSL} x509 -noout -pubkey -in ${CCERT} 2>&1 | ${OPENSSL} md5 | awk '{print $2}');
        echo "${GREEN}[OK]${RESET} The cert md5 hash: ${BOLD}${HCERT}${RESET}";
    fi;
    echo;
}

do_validate_key()
{
    CKEY="$1";
    ${OPENSSL} pkey -pubout -in ${CKEY} >/dev/null 2>&1;
    RES=$?;
    echo "[INFO] Validating CERT ${BOLD}${CKEY}${RESET}";
    if [ "${RES}" -gt "0" ]; then
        echo "${RED}[ERROR]${RESET} File ${CKEY} is not a valid KEY";
        exit 1;
    else
        HKEY=$(${OPENSSL} pkey -pubout -in ${CKEY} 2>&1 | ${OPENSSL} md5 | awk '{print $2}');
        echo "${GREEN}[OK]${RESET} The key md5 hash: ${BOLD}${HKEY}${RESET}";
    fi;
    echo;
}

# PRINT USAGE
[ "$#" -lt "2" ] && do_print_usage;

# SET PARAMS
PCERT="$1";
PKEY="$2";

[ -d "/usr/local/directadmin/" ] || die "${RED}[ERROR]${RESET} DirectAdmin is not installed here. Terminating..." 1;
[ -f "/usr/local/directadmin/custombuild/options.conf" ] || die "${RED}[ERROR]${RESET} CustomBuild is not installed here. Terminating..." 2;

do_print_copyright;
do_validate_cert "${PCERT}";
do_validate_key "${PKEY}";

if [ "${HKEY}" == "${HCERT}" ]; then
    echo "${GREEN}[OK]${RESET} CERT and KEY match each other!";
    echo;
else
    echo "${RED}[ERROR]${RESET} CERT and KEY do not match each other!";
    exit 1;
fi;

if [ -n "$3" ] && [ -f "$3" ]; then
    PCACERT="$3";
    echo "[INFO] You provided CACERT ${BOLD}${PCACERT}${RESET}";
    do_validate_cert "${PCACERT}";
fi;

# DIRECTADMIN
c=$(echo ${SERVICES} | grep -c directadmin);
[ "$c" -eq "1" ] && do_cert_directadmin;

WEBSERVER=$(grep ^webserver= /usr/local/directadmin/custombuild/options.conf | awk -F= '{print $2}');

case "${WEBSERVER}" in
    apache)
        # APACHE
        do_cert_apache;
    ;;
    nginx)
        # NGINX
        do_cert_nginx;
    ;;
    nginx_apache)
        # NGINX + APACHE
        do_cert_apache;
        do_cert_nginx;
    ;;
    litespeed)
        # LITESPEED
        do_cert_litespeed;
    ;;
    openlitespeed)
        # OPENLITESPEED
        do_cert_openlitespeed;
    ;;
esac;

# EXIM
c=$(echo ${SERVICES} | grep -c exim);
if [ "$c" -eq "1" ]; then
    do_cert_exim_dovecot;
else
    c=$(echo ${SERVICES} | grep -c dovecot);
    [ "$c" -eq "1" ] && do_cert_exim_dovecot;
fi;

# PureFTPd
c=$(grep -c ^ftpd=pureftpd /usr/local/directadmin/custombuild/options.conf);
if [ "${c}" -eq "1" ]; then
    do_cert_pureftpd;
fi;

exit 0;
