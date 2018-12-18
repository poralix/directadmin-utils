#!/bin/bash
#
# A script to install/update/remove pecl extension
# for all installed by CustomBuild 2.x PHP versions
# Written by Alex Grebenschikov (support@poralix.com)
#
# =====================================================
# versions: 0.7-beta $ Tue Dec 18 13:54:09 +07 2018
#           0.6-beta $ Wed Dec 12 11:23:45 +07 2018
#           0.5-beta $ Tue Jun 12 02:27:32 PDT 2018
#           0.4-beta $ Tue May 15 14:08:57 +07 2018
#           0.3-beta $ Wed May  2 20:36:54 +07 2018
#           0.2-beta $ Tue Mar 17 12:40:51 NOVT 2015
# =====================================================
#set -x

PWD=`pwd`;
WORKDIR="/usr/local/src";
PECL=`ls -1 /usr/local/php*/bin/pecl | head -1`;
LANG=C;
FILE="";
EXT="";
PHPVER="";
BN="`tput -Txterm bold`"
BF="`tput -Txterm sgr0`"

function do_usage()
{
    echo "
# ===================================================== #
# A script to install/update/remove pecl extension      #
# for all installed by CustomBuild 2.x PHP versions     #
# Written by Alex Grebenschikov(support@poralix.com)    #
# Version: 0.7-beta $ Tue Dec 18 13:54:09 +07 2018      #
# ===================================================== #

Usage:

$0 <command> <pecl_extension> [<options>]

        Supported commands:

            install   - to install extension
            remove    - to remove extension
            status    - show status of an extension

        options:

            --ver=VER - to install a specified version of an extension

            --beta    - to install a beta version of an extension

            --php=VER - to install extension for one PHP version
                        digits only (only one version at a time):
                        52, 53, 54, 55, 56, 70, 71, 72, 73, etc

";

    exit 1;
}

function do_update()
{
    tmpdir=`mktemp -d ${WORKDIR}/tmp.XXXXXXXXXX`;
    PHPIZE=$1;
    if [ -x "${PHPIZE}" ];
    then
    {
        PHPVER=`echo ${PHPIZE} | cut -d\/ -f4`
        echo "${BN}Installing ${EXT} for ${PHPVER}${BF}";
        PHPDIR=`dirname ${PHPIZE}`;
        cd ${WORKDIR};
        rm -rfv ${tmpdir}/*;
        tar -zxvf ${FILE} --directory=${tmpdir};
        DIR=`ls -1d ${tmpdir}/${EXT}* | head -1`;
        if [ -d "${DIR}" ];
        then
        {
            cd ${DIR};
            ${PHPIZE};
            ./configure --with-php-config=${PHPDIR}/php-config;
            RETVAL=$?;
            if [ "${RETVAL}" == "0" ];
            then
            {
                make && make install;
                RETVAL=$?;
                if [ "${RETVAL}" == "0" ];
                then
                {
                    echo "${BN}[OK] Installation of ${EXT} for ${PHPVER} completed!${BF}";
                }
                else
                {
                    echo "${BN}[ERROR] Installation of ${EXT} for ${PHPVER} failed${BF}";
                }
                fi;
                echo -ne '\007';
            }
            else
            {
                echo "${BN}[ERROR] Configure of ${EXT} failed${BF}";
            }
            fi;
        }
        fi;
    }
    else
    {
        echo "ERROR! Executable ${PHPIZE} not found!";
        exit 1;
    }
    fi;
    rm -rf ${tmpdir};
}

do_update_ini()
{
    EXT_DIR=$(/usr/local/${1}/bin/php -i 2>&1 | grep ^extension_dir | awk '{print $3}');
    INI_DIR="/usr/local/${1}/lib/php.conf.d";
    INI_FILE="${INI_DIR}/99-custom.ini";
    [ -f "${INI_FILE}" ] || INI_FILE="/usr/local/${1}/lib/php.conf.d/90-custom.ini";
    ROW="extension=${EXT}.so";

    if [ -f "${EXT_DIR}/${EXT}.so" ];
    then
    {
        echo "${BN}[OK] Found ${EXT}.so. Enabling the extension in ${INI_FILE}${BF}";
        grep -m1 -q "^${ROW}" "${INI_FILE}" >/dev/null 2>&1 || echo "${ROW}" >> ${INI_FILE};
        /usr/local/${1}/bin/php -i 2>&1 | grep -i "^${EXT}" | grep -v 'Configure Command' | head -3;
    }
    else
    {
        for INI_FILE in `ls -1 ${INI_DIR}/*.ini`;
        do
            echo "${BN}[ERROR] Could not find ${EXT_DIR}/${EXT}.so. Removing extension from ${INI_FILE}${BF}";
            grep -m1 -q "^${ROW}" "${INI_FILE}" &&  perl -pi -e  "s#^${ROW}##" ${INI_FILE};
        done;
    }
    fi;
}


verify_php_version()
{
    if [ -n "${PVN}" ];
    then
    {
        if [ -d "/usr/local/php${PVN}" ] && [ -f "/usr/local/php${PVN}/bin/php" ];
        then
        {
            PHPVER="php${PVN}";
            PECL="/usr/local/php${PVN}/bin/pecl";
        }
        else
        {
            echo "${BN}[ERROR] PHP version php${PVN} was not found!${BF}";
            exit 2;
        }
        fi;
        if [ ! -x "${PECL}" ]; then
            echo "${BN}[ERROR] PECL for PHP version php${PVN} was not found!${BF}";
            exit 2;
        fi;
    }
    fi;
}


do_remove()
{
    verify_php_version;
    if [ -n "${PVN}" ]; then
    {
        PHP_VERSIONS="${PVN}";
    }
    else
    {
        PHP_VERSIONS=`ls -1 /usr/local/php*/bin/php | sort -n | egrep -o '(5|7)[0-9]+' | xargs`;
    }
    fi;

    for PHP_VERSION in ${PHP_VERSIONS};
    do
    {
        PHPVER="php${PHP_VERSION}";

        EXT_DIR=$(/usr/local/${PHPVER}/bin/php -i 2>&1 | grep ^extension_dir | awk '{print $3}');
        EXT_FILE="${EXT_DIR}/${EXT}.so";
        if [ -f "${EXT_FILE}" ]; then
        {
            rm -f "${EXT_FILE}";
            echo "${BN}[OK] The extension ${EXT} for PHP ${PHP_VERSION} found! Removing it...${BF}";
        }
        else
        {
            echo "${BN}[Warning] The extension ${EXT} for PHP ${PHP_VERSION} not found! Nothing to disable...${BF}";
        }
        fi;
        do_update_ini ${PHPVER} >/dev/null 2>&1;
        cat ${INI_FILE};
    }
    done;
}

do_install()
{
    verify_php_version;

    cd ${WORKDIR};

    if [ -x "${PECL}" ];
    then
    {
        tmpfile=$(mktemp ${WORKDIR}/tmp.XXXXXXXXXX);
        ${PECL} channel-update pecl.php.net;
        if [ "${BETA}" == "1" ]; then
            ${PECL} download ${EXT}-beta 2>&1 | tee ${tmpfile};
        elif [ -n "${EXT_VERSION}" ]; then
            ${PECL} download ${EXT}-${EXT_VERSION} 2>&1 | tee ${tmpfile};
        else
            ${PECL} download ${EXT} 2>&1 | tee ${tmpfile};
        fi;
        FILE=$(cat ${tmpfile} | grep ^File | grep downloaded | cut -d\  -f2);
        rm -f ${tmpfile};
    }
    else
    {
        echo "${BN}[ERROR] No pecl found in ${PECL}${BF}";
        exit 1;
    }
    fi;

    if [ -f "${FILE}" ]
    then
    {
        if [ -z "${PHPVER}" ];
        then
        {
            for PHPIZE in `ls -1 /usr/local/php*/bin/phpize`;
            do
            {
                PHPVER=$(echo ${PHPIZE} | grep -o "[0-9]*");
                do_update ${PHPIZE};
                do_update_ini ${PHPVER};
            }
            done;
        }
        else
        {
            do_update /usr/local/${PHPVER}/bin/phpize;
            do_update_ini ${PHPVER};
        }
        fi;
    }
    else
    {
        echo "Failed to download a file";
        exit 2;
    }
    fi;

    [ -d "${PWD}" ] && cd ${PWD};
}

do_status()
{
    verify_php_version;
    if [ -n "${PVN}" ]; then
    {
        PHP_VERSIONS="${PVN}";
    }
    else
    {
        PHP_VERSIONS=`ls -1 /usr/local/php*/bin/php | sort -n | egrep -o '(5|7)[0-9]+' | xargs`;
    }
    fi;

    for PHP_VERSION in ${PHP_VERSIONS};
    do
    {
        PHPVER="php${PHP_VERSION}";

        EXT_DIR=$(/usr/local/${PHPVER}/bin/php -i 2>&1 | grep ^extension_dir | awk '{print $3}');
        EXT_FILE="${EXT_DIR}/${EXT}.so";
        if [ -f "${EXT_FILE}" ]; then
        {
            #echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${PHP_VERSION}${BF} found!";
            IS_ENABLED=$(/usr/local/${PHPVER}/bin/php -m | grep -m1 "^${EXT}$");
            if [ -n "${IS_ENABLED}" ]; then
            {
                echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${PHP_VERSION}${BF} seems to be enabled!";
                /usr/local/${PHPVER}/bin/php -i | grep -i ^${EXT};
            }
            else
            {
                echo "${BN}[WARNING]${BF} The extension ${BN}${EXT}${BF} is probably not enabled for ${BN}PHP ${PHP_VERSION}${BF}! I did not detect it.";
            }
            fi;
        }
        else
        {
            echo "${BN}[Warning]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${PHP_VERSION}${BF} not found!";
        }
        fi;
    }
    done;
}

CMD="${1}";
EXT="${2}";
PVN="";
BETA="";

[ -n "${CMD}" ] || do_usage;
[ -n "${EXT}" ] || do_usage;

for ARG in $@;
do
    case "${ARG}" in
        --beta)
            BETA=1;
        ;;
        --php=*)
            PVN=`echo "${ARG}" | cut -d\= -f2 | egrep -o '^(5|7)[0-9]+'`;
            [ -z "${PVN}" ] && do_usage;
        ;;
        --ver=*)
            EXT_VERSION=`echo "${ARG}" | cut -d\= -f2`;
            [ -z "${EXT_VERSION}" ] && do_usage;
        ;;
    esac;
done;

if [ -n "${BETA}" ] && [ -n "${EXT_VERSION}" ]; then
    echo "Can not use --beta and --ver= together at the same time...";
    exit 2;
fi;

case "${CMD}" in
    install)
        do_install;
    ;;
    remove)
        BETA=0;
        do_remove;
    ;;
    status)
        BETA=0;
        do_status;
    ;;
    *)
        BETA=0;
        do_usage;
    ;;
esac;


exit 0;
