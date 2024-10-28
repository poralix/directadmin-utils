#!/bin/bash
#
# A script to install/update/remove pecl extension
# for all installed by CustomBuild 2.x PHP versions
# Written by Alex Grebenschikov (support@poralix.com)
#
# =====================================================
# versions: 0.13-beta $ Mon Oct 28 15:55:09 +07 2024
#           0.12-beta $ Mon May  9 18:51:05 +07 2022
#           0.11-beta $ Thu Feb 24 22:49:14 +07 2022
#           0.10-beta $ Mon Jan 24 17:06:22 +07 2022
#           0.9-beta $ Sat Apr  3 11:19:27 PDT 2021
#           0.8-beta $ Thu Mar 21 17:54:46 +07 2019
#           0.7-beta $ Tue Dec 18 13:54:09 +07 2018
#           0.6-beta $ Wed Dec 12 11:23:45 +07 2018
#           0.5-beta $ Tue Jun 12 02:27:32 PDT 2018
#           0.4-beta $ Tue May 15 14:08:57 +07 2018
#           0.3-beta $ Wed May  2 20:36:54 +07 2018
#           0.2-beta $ Tue Mar 17 12:40:51 NOVT 2015
# =====================================================
#set -x

PWD="$(pwd)";
WORKDIR="/usr/local/src";
PECL=$(find /usr/local/php*/bin/pecl /usr/local/bin/pecl 2>/dev/null | head -1);
LANG=C;
FILE="";
EXT="";
PHPVER="";
BN="$(tput -Txterm bold)"
BF="$(tput -Txterm sgr0)"

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

find_extension_version()
{
    if [ -z "${EXT_VERSION}" ];
    then
    {
        case "${PHPVER}" in
            52|53|54|55|56)
                case "${EXT}" in
                    redis)
                        EXT_VERSION_LEGACY="3.1.6";
                    ;;
                    *)
                        EXT_VERSION_LEGACY="";
                    ;;
                esac;
            ;;
            70|71|72|73)
                case "${EXT}" in
                    redis)
                        EXT_VERSION_LEGACY="5.3.7";
                    ;;
                    *)
                        EXT_VERSION_LEGACY="";
                    ;;
                esac;
            ;;
            *)
                EXT_VERSION_LEGACY="";
            ;;
        esac;
    }
    fi;
    test -n "${EXT_VERSION_LEGACY}" && echo "${BN}Using legacy version=${EXT_VERSION_LEGACY} for extension=${EXT} for PHP=${PHPVER}${BF}";
    test -z "${EXT_VERSION_LEGACY}" && echo "${BN}Using default version for extension=${EXT} for PHP=${PHPVER}${BF}";
}

do_usage()
{
    echo "
# ============================================================ #
#     A script to install/update/remove PECL extension         #
#     for all installed by CustomBuild 2.x PHP versions        #
# ============================================================ #
#     IMPORTANT: DirectAdmin servers are only supported        #
# ============================================================ #
#     Written by Alex Grebenschikov(support@poralix.com)       #
#     Version: 0.13-beta $ Mon Oct 28 15:55:09 +07 2024        #
# ============================================================ #

Usage:

    $0 <command> <pecl_extension> [<options>]

Supported commands:

    install   - to install PECL extension
    remove    - to remove PECL extension
    status    - show a status of PECL extension for a PHP version
    version   - show a PECL extension version installed

Supported options:

    --ver=VER - to install a specified version of an
                extension

    --beta    - to install a beta version of an extension

    --php=VER - to install extension for one PHP version
                digits only (only one version at a time):
                52, 53, 54, 55, 56, 70, 71, 72, 73, 74, 80,
                81, 82, 83 etc

";

    exit 1;
}

do_update()
{
    tmpdir=$(mktemp -d "${WORKDIR}/tmp.XXXXXXXXXX");
    PHPIZE=$1;
    if [ -x "${PHPIZE}" ];
    then
    {
        tmpfile=$(mktemp "${WORKDIR}/tmp.XXXXXXXXXX");
        "${PECL}" channel-update pecl.php.net;
        EXT_FULL="${EXT}";

        if [ -z "${EXT_VERSION_LEGACY}" ];
        then
        {
            if [ "${BETA}" == "1" ]; then
                EXT_FULL="${EXT}-beta";
            elif [ -n "${EXT_VERSION}" ]; then
                EXT_FULL="${EXT}-${EXT_VERSION}";
            fi;
        }
        else
        {
            EXT_FULL="${EXT}-${EXT_VERSION_LEGACY}";
        }
        fi;
        "${PECL}" download "${EXT_FULL}" 2>&1 | tee "${tmpfile}";
        FILE=$(grep "^File" "${tmpfile}" | grep downloaded | cut -d\  -f2);
        rm -f "${tmpfile}";

        if [ -f "${FILE}" ];
        then
        {
            PHPVER=$(echo "${PHPIZE}" | cut -d/ -f4);
            echo "${BN}Installing ${EXT} for ${PHPVER}${BF}";
            PHPDIR=$(dirname "${PHPIZE}");
            cd "${WORKDIR}";
            rm -rfv "${tmpdir:?}"/*;
            tar -zxvf "${FILE}" --directory="${tmpdir}";
            DIR=$(find "${tmpdir}/${EXT}"* -type d | head -1);
            if [ -d "${DIR}" ];
            then
            {
                cd "${DIR}";
                "${PHPIZE}";
                ./configure "--with-php-config=${PHPDIR}/php-config";
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
                cd "${WORKDIR}";
            }
            fi;
        }
        else
        {
            echo "${BN}[ERROR] Failed to download extension file of ${EXT} for ${PHPVER}${BF}";
        }
        fi;
    }
    else
    {
        echo "ERROR! Executable ${PHPIZE} not found!";
        exit 1;
    }
    fi;
    rm -rf "${tmpdir}";
}

do_update_ini()
{
    EXT_DIR=$("/usr/local/${1}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
    INI_DIR="/usr/local/${1}/lib/php.conf.d";
    [ -d "${INI_DIR}" ] || mkdir -p "${INI_DIR}";
    INI_FILE="${INI_DIR}/99-custom.ini";
    [ -f "${INI_FILE}" ] || INI_FILE="/usr/local/${1}/lib/php.conf.d/90-custom.ini";

    case "${EXT}" in
        xdebug)
            ROW="zend_extension=${EXT}.so";
        ;;
        *)
            ROW="extension=${EXT}.so";
        ;;
    esac;

    if [ -f "${EXT_DIR}/${EXT}.so" ];
    then
    {
        echo "${BN}[OK] Found ${EXT}.so. Enabling the extension in ${INI_FILE}${BF}";
        grep -m1 -q "^${ROW}" "${INI_FILE}" >/dev/null 2>&1 || echo "${ROW}" >> "${INI_FILE}";
        "/usr/local/${1}/bin/php" -i 2>&1 | grep -i "^${EXT}" | grep -v 'Configure Command' | head -3;
    }
    else
    {
        while read -r INI_FILE
        do
            echo "${BN}[ERROR] Could not find ${EXT_DIR}/${EXT}.so. Removing extension from ${INI_FILE}${BF}";
            grep -m1 -q "^${ROW}" "${INI_FILE}" && perl -pi -e "s#^${ROW}\n##" "${INI_FILE}";
            grep -m1 -q "^${ROW}" "${INI_FILE}" && perl -pi -e "s#^${ROW}##" "${INI_FILE}";
        done < <(find ${INI_DIR}/*.ini);
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
        PHP_VERSIONS=$(find /usr/local/php*/bin/php | sort -n | egrep -o '(5|7|8|9)[0-9]+' | xargs); #'
    }
    fi;

    for PHP_VERSION in ${PHP_VERSIONS};
    do
    {
        PHPVER="php${PHP_VERSION}";

        EXT_DIR=$("/usr/local/${PHPVER}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
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
        do_update_ini "${PHPVER}" >/dev/null 2>&1;
        do_restart_webserver "${PHPVER}";
        test -f "${INI_FILE}" && cat "${INI_FILE}";
    }
    done;
}

do_install()
{
    verify_php_version;
    cd "${WORKDIR}";

    if [ ! -x "${PECL}" ];
    then
    {
        echo "${BN}[ERROR] No pecl found in ${PECL}${BF}";
        exit 1;
    }
    fi;

    if [ -z "${PHPVER}" ];
    then
    {
        while read -r PHPIZE
        do
        {
            PHPVER=$(echo "${PHPIZE}" | grep -o "[0-9]*");
            find_extension_version "${PHPVER}";
            do_update "${PHPIZE}";
            do_update_ini "${PHPVER}";
            do_restart_webserver "${PHPVER}";
            echo; sleep 1;
        }
        done < <(find /usr/local/php*/bin/phpize);
    }
    else
    {
        find_extension_version "${PHPVER}";
        do_update "/usr/local/${PHPVER}/bin/phpize";
        do_update_ini "${PHPVER}";
        do_restart_webserver "${PHPVER}";
    }
    fi;

    [ -d "${PWD}" ] && cd "${PWD}";
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
        PHP_VERSIONS=$(find /usr/local/php*/bin/php | sort -n | egrep -o '(5|7|8|9)[0-9]+' | xargs); #'
    }
    fi;

    for PHP_VERSION in ${PHP_VERSIONS};
    do
    {
        PHPVER="php${PHP_VERSION}";

        EXT_DIR=$("/usr/local/${PHPVER}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
        EXT_FILE="${EXT_DIR}/${EXT}.so";
        if [ -f "${EXT_FILE}" ]; then
        {
            #echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${PHP_VERSION}${BF} found!";
            IS_ENABLED=$("/usr/local/${PHPVER}/bin/php" -m | grep -m1 "^${EXT}$");
            if [ -n "${IS_ENABLED}" ]; then
            {
                echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${PHP_VERSION}${BF} seems to be enabled!";
                OLD_IFS="${IFS}"; IFS=$'\n';
                while read -r ROW
                do
                    echo "[${PHPVER}] ${ROW}";
                done < <("/usr/local/${PHPVER}/bin/php" -i | grep -i "^${EXT}");
                IFS="${OLD_IFS}";
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

do_restart_webserver()
{
    DOTVER=$(echo "${1}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
    PHP_INSTANCE=$(grep "^php[1-9]_release=${DOTVER}" /usr/local/directadmin/custombuild/options.conf | cut -d_ -f1);
    if [ -n "${PHP_INSTANCE}" ]; then
    {
        PHP_MODE_DEFAULT=$(grep "^php1_mode=" /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);
        PHP_MODE=$(grep "^${PHP_INSTANCE}_mode=" /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);
        PHP_MODE=${PHP_MODE:-$PHP_MODE_DEFAULT};
        if [ "${PHP_MODE}" == "php-fpm" ]; then
        {
            echo "${BN}[INFO]${BF} Going to restart PHP-FPM ${DOTVER}!";
            do_restart_service "php-fpm${DOTVER//./}";
        }
        elif [ "${PHP_MODE}" == "lsphp" ]; then
        {
            echo "${BN}[INFO]${BF} Going to reload PHP ${DOTVER} instances (${PHP_MODE})!";
            killall lsphp;
        }
        else
        {
            echo "${BN}[INFO]${BF} Going to restart a webserver for PHP ${DOTVER} (${PHP_MODE})!";
            WEBSERVER=$(grep ^webserver= /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);

            case "${WEBSERVER}" in
                nginx_apache|apache)
                    do_restart_service "httpd";
                ;;
                openlitespeed|litespeed)
                    do_restart_service "litespeed";
                ;;
                nginx)
                    do_restart_service "nginx";
                ;;
            esac;
        }
        fi;
    }
    else
    {
        echo "${BN}[Warning]${BF} The PHP version ${BN}${DOTVER}${BF} isn't managed by DirectAdmin!";
    }
    fi;
    echo '';
}

do_restart_service()
{
    echo "${BN}[INFO]${BF} Restarting ${1}!";

    if [ -e "/bin/systemctl" ]; then
    {
        /bin/systemctl restart "${1}.service";
    }
    else
    {
        /sbin/service "${1}" restart;
    }
    fi;
}

CMD="${1}";
EXT="${2}";
PVN="";
BETA="";

[ -n "${CMD}" ] || do_usage;
[ -n "${EXT}" ] || do_usage;

for ARG in "$@";
do
    case "${ARG}" in
        --beta)
            BETA=1;
        ;;
        --php=*)
            PVN=$(echo "${ARG}" | cut -d= -f2 | egrep -o '^(5|7|8)[0-9]+'); #'
            [ -z "${PVN}" ] && do_usage;
        ;;
        --ver=*)
            EXT_VERSION=$(echo "${ARG}" | cut -d= -f2);
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
    version)
        BETA=0;
        do_status | grep -i 'version';
    ;;
    *)
        BETA=0;
        do_usage;
    ;;
esac;


exit 0;
