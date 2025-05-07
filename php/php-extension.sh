#!/bin/bash
# ======================================================
#
#  A script to install/update/remove PHP extensions
#  for all installed by CustomBuild 2.x PHP versions
#  Written by Alex Grebenschikov (support@poralix.com)
#
# ======================================================
#  Version: 0.17.3-beta $ Wed May  7 18:00:27 +07 2025
#  Created:    0.2-beta $ Tue Mar 17 12:40:51 NOVT 2015
# ======================================================
#
#set -x

PWD="$(pwd)";
WORKDIR="/usr/local/src";
LANG=C;
FILE="";
EXT="";
BN="$(tput -Txterm bold)"
BF="$(tput -Txterm sgr0)"

redirect_cmd()
{
    if [ "${QUIET}" == "1" ];
    then
        "$@" > /dev/null 2>&1;
    else
        "$@";
    fi;
    return "$?";
}

verify_php_version()
{
    local loc_php_version loc_pecl_bin;
    loc_php_version="${1}";

    if [ -n "${loc_php_version}" ];
    then
    {
        if [ ! -d "/usr/local/php${loc_php_version}/" ] || [ ! -f "/usr/local/php${loc_php_version}/bin/php" ];
        then
        {
            echo "${BN}[ERROR] PHP version php${loc_php_version} was not found!${BF}";
            exit 2;
        }
        fi;

        loc_pecl_bin="/usr/local/php${loc_php_version}/bin/pecl";
        if [ ! -x "${loc_pecl_bin}" ]; then
            echo "${BN}[ERROR] PECL for PHP version php${loc_php_version} was not found!${BF}";
            exit 2;
        fi;
    }
    fi;
}

find_extension_version()
{
    local loc_php_version loc_php_dotver;
    loc_php_version="${1:?}";
    loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'

    if [ -z "${EXT_VERSION}" ];
    then
    {
        case "${loc_php_version}" in
            52|53|54|55|56)
                case "${EXT}" in
                    apcu)
                        EXT_VERSION_LEGACY="4.0.11";
                    ;;
                    igbinary)
                        EXT_VERSION_LEGACY="2.0.8";
                    ;;
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
                case "${EXT}" in
                    redis)
                        EXT_VERSION_LEGACY="";
                        if [ "${IS_CENTOS_7}" == "1" ];
                        then
                        {
                            EXT_VERSION_LEGACY="5.3.7";
                        }
                        fi;
                    ;;
                    *)
                        EXT_VERSION_LEGACY="";
                    ;;
                esac;
            ;;
        esac;
    }
    fi;
    test -n "${EXT_VERSION_LEGACY}" && echo "${BN}[OK] Using legacy version=${EXT_VERSION_LEGACY} for extension=${EXT} for PHP ${loc_php_dotver}${BF}";
    test -z "${EXT_VERSION_LEGACY}" && echo "${BN}[OK] Using default version for extension=${EXT} for PHP ${loc_php_dotver}${BF}";
}

do_install_sourceguardian()
{
    if [ "${SOURCEGUARDIAN_INSTALLED}" == "1" ];
    then
        echo "${BN}[OK] Already installed sourceguardian loaders${BF}";
        return 0;
    fi;

    echo "${BN}[OK] Going to download sourceguardian loaders${BF}";
    mkdir -p "${SOURCEGUARDIAN_DIR}";
    cd "${SOURCEGUARDIAN_DIR}" && curl -s https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz --output "${SOURCEGUARDIAN_DIR}/loaders.linux-x86_64.tar.gz";
    if [ "$?" == "0" ] && [ -f "${SOURCEGUARDIAN_DIR}/loaders.linux-x86_64.tar.gz" ];
    then
    {
        echo "${BN}[OK] Unpacking sourceguardian loaders to ${SOURCEGUARDIAN_DIR}${BF}";
        cd "${SOURCEGUARDIAN_DIR}" && tar -xzf "${SOURCEGUARDIAN_DIR}/loaders.linux-x86_64.tar.gz";
        if [ "$?" == "0" ];
        then
        {
            SOURCEGUARDIAN_INSTALLED=1;
            rm -f "${SOURCEGUARDIAN_DIR}/loaders.linux-x86_64.tar.gz";
        }
        else
        {
            SOURCEGUARDIAN_INSTALLED=0;
            echo "${BN}[ERROR] Failed to unpack sourceguardian loaders${BF}";
            exit 1;
        }
        fi;
    }
    else
    {
        SOURCEGUARDIAN_INSTALLED=0;
        echo "${BN}[ERROR] Failed to download sourceguardian loaders${BF}";
        exit 1;
    }
    fi;
}

do_usage()
{
    echo "
# ============================================================ #
#     A script to install/update/remove PHP extensions         #
#     for all installed by CustomBuild 2.x PHP versions        #
# ============================================================ #
#     IMPORTANT: DirectAdmin servers are only supported        #
# ============================================================ #
#     Written by Alex Grebenschikov(support@poralix.com)       #
#     Version: 0.17.3-beta $ Wed May  7 18:00:27 +07 2025      #
# ============================================================ #

Usage:

    $0 <command> <pecl_extension> [<options>]

Supported commands:

    install        - to install PECL extension
    remove         - to remove PECL extension
    status         - show a status of PECL extension for a PHP version
    version        - show a PECL extension version installed
    selfupdate     - update this script from GitHub

Supported options:

    --ver=VER - to install a specified version of an
                extension

    --beta    - to install a beta version of an extension

    --php=VER - to install extension for one PHP version
                digits only (only one version at a time):
                52, 53, 54, 55, 56, 70, 71, 72, 73, 74, 80,
                81, 82, 83, 84 etc

    --verbose - show messages from configure/make operations
";

    exit 1;
}

do_disable_extension_in_da()
{
    local loc_php_version loc_php_da_ini_file;
    loc_php_version="${1:?}";
    loc_php_da_ini_file="/usr/local/php${loc_php_version}/lib/php.conf.d/10-directadmin.ini";
    if grep -q "^php_${EXT}=yes$" /usr/local/directadmin/custombuild/options.conf;
    then
        echo "${BN}[OK] Disabling ${EXT} for PHP in DirectAdmin CustomBuild${BF}";
        /usr/local/directadmin/directadmin build set php_${EXT} no;
    else
        if grep -q "^php_${EXT}=no$" /usr/local/directadmin/custombuild/options.conf;
        then
            echo "${BN}[NOTICE] ${EXT} for PHP is already disabled in DirectAdmin CustomBuild${BF}";
        else
            echo "${BN}[NOTICE] ${EXT} for PHP is not managed by DirectAdmin CustomBuild${BF}";
        fi;
    fi;
    if grep -q "^extension=${EXT}.so$" "${loc_php_da_ini_file}";
    then
        echo "${BN}[OK] Disabling ${EXT} in PHP ${loc_php_version} installed by DirectAdmin CustomBuild${BF}";
        perl -pi -e "s/^extension=${EXT}.so//" "${loc_php_da_ini_file}";
    fi;
}

do_update()
{
    local loc_php_version loc_php_bindir loc_pecl_bin loc_phpize_bin loc_php_dotver loc_configure_options loc_extension_dir;
    loc_php_version="${1:?}";
    loc_php_bindir="/usr/local/php${loc_php_version}/bin";
    loc_pecl_bin="/usr/local/php${loc_php_version}/bin/pecl";
    loc_phpize_bin="/usr/local/php${loc_php_version}/bin/phpize";
    loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
    loc_extension_dir=$("/usr/local/php${loc_php_version}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
    loc_configure_options='';

    case "${EXT}" in
        redis)
            loc_configure_options="--enable-redis-lzf";
            test -e /usr/include/zstd.h && loc_configure_options="${loc_configure_options} --enable-redis-zstd";
        ;;
        igbinary)
            loc_configure_options="";
            test -e "${loc_extension_dir}/redis.so" && loc_configure_options="${loc_configure_options} --enable-redis-igbinary";
        ;;
        *)
            loc_configure_options='';
        ;;
    esac;

    if [ -x "${loc_phpize_bin}" ];
    then
    {
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

        tmpdir=$(mktemp -d "${WORKDIR}/tmp.XXXXXXXXXX");
        tmpfile=$(mktemp "${WORKDIR}/tmp.XXXXXXXXXX");

        echo "${BN}[OK] Updating ${loc_pecl_bin}${BF}";
        redirect_cmd "${loc_pecl_bin}" channel-update pecl.php.net;
        echo "${BN}[OK] Downloading ${EXT_FULL} for PHP ${loc_php_dotver}${BF}";
        "${loc_pecl_bin}" download "${EXT_FULL}" 2>&1 | tee "${tmpfile}";
        FILE=$(grep "^File" "${tmpfile}" | grep downloaded | cut -d\  -f2);
        rm -f "${tmpfile}";

        if [ -f "${FILE}" ];
        then
        {
            echo "${BN}[OK] Going to install extension ${EXT} for PHP ${loc_php_dotver}${BF}";

            cd "${WORKDIR}";
            rm -rfv "${tmpdir:?}"/*;
            tar -zxf "${FILE}" --directory="${tmpdir}";
            DIR=$(find "${tmpdir}/${EXT}"* -type d | head -1);
            if [ -d "${DIR}" ];
            then
            {
                cd "${DIR}";
                echo "${BN}[OK] Configuring ${EXT_FULL} for PHP ${loc_php_dotver}${BF}";
                redirect_cmd "${loc_phpize_bin}";
                redirect_cmd ./configure ${loc_configure_options} "--with-php-config=${loc_php_bindir}/php-config";
                RETVAL=$?;
                if [ "${RETVAL}" == "0" ];
                then
                {
                    echo "${BN}[OK] Compiling ${EXT_FULL} for PHP ${loc_php_dotver}${BF}";
                    redirect_cmd make && redirect_cmd make install;
                    RETVAL=$?;
                    if [ "${RETVAL}" == "0" ];
                    then
                    {
                        echo "${BN}[OK] Installation of ${EXT} for PHP ${loc_php_dotver} completed!${BF}";
                        do_disable_extension_in_da "${loc_php_version}";
                    }
                    else
                    {
                        echo "${BN}[ERROR] Installation of ${EXT} for PHP ${loc_php_dotver} failed${BF}";
                    }
                    fi;
                    echo -ne '\007';
                }
                else
                {
                    echo "${BN}[ERROR] Configure of ${EXT} for PHP ${loc_php_dotver} failed${BF}";
                }
                fi;
                cd "${WORKDIR}";
            }
            fi;
        }
        else
        {
            echo "${BN}[ERROR] Failed to download extension file of ${EXT} for PHP ${loc_php_dotver}${BF}";
        }
        fi;
    }
    else
    {
        echo "ERROR! Executable ${loc_phpize_bin} not found!";
        exit 1;
    }
    fi;
    rm -rf "${tmpdir}";
}

do_update_ini()
{
    local loc_php_version loc_php_dotver loc_extension_dir loc_php_inidir loc_php_inifile loc_inifile;
    loc_php_version="${1:?}";
    loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
    loc_extension_dir=$("/usr/local/php${loc_php_version}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');

    loc_php_inidir="/usr/local/php${1}/lib/php.conf.d";
    test -d "${loc_php_inidir}" || mkdir -p "${loc_php_inidir}";

    loc_inifile=${2:-custom};
    loc_php_inifile="${loc_php_inidir}/99-${loc_inifile}.ini";
    test -f "${loc_php_inifile}" || loc_php_inifile="${loc_php_inidir}/90-${loc_inifile}.ini";

    if [ "${EXT}" == "sourceguardian" ];
    then
    {
        if [ -f "${SOURCEGUARDIAN_DIR}/ixed.${loc_php_dotver}.lin" ];
        then
        {
            echo "${BN}[OK] Found ${EXT}. Enabling the extension in ${loc_php_inifile}${BF}";
            echo "; Created by $0 script" > "${loc_php_inifile}";
            echo "[sourceguardian]" >> "${loc_php_inifile}";
            echo "zend_extension=${SOURCEGUARDIAN_DIR}/ixed.${loc_php_dotver}.lin" >> "${loc_php_inifile}";
        }
        else
        {
            echo "${BN}[WARNING] Could not found ${EXT}. Removing the extension from ${loc_php_inifile}${BF}";
            rm -f "${loc_php_inifile}";
        }
        fi;
    }
    else
    {
        case "${EXT}" in
            xdebug)
                ROW="zend_extension=${EXT}.so";
            ;;
            *)
                ROW="extension=${EXT}.so";
            ;;
        esac;

        if [ -f "${loc_extension_dir}/${EXT}.so" ];
        then
        {
            echo "${BN}[OK] Found ${EXT}.so. Enabling the extension in ${loc_php_inifile}${BF}";
            grep -m1 -q "^${ROW}" "${loc_php_inifile}" >/dev/null 2>&1 || echo "${ROW}" >> "${loc_php_inifile}";
            "/usr/local/php${1}/bin/php" -i 2>&1 | grep -i "^${EXT}" | grep -v 'Configure Command' | head -3;
        }
        else
        {
            while read -r INI_FILE;
            do
                echo "${BN}[WARNING] Could not find ${loc_extension_dir}/${EXT}.so. Removing extension from ${INI_FILE}${BF}";
                grep -m1 -q "^${ROW}" "${INI_FILE}" && perl -pi -e "s#^${ROW}\n##" "${INI_FILE}";
                grep -m1 -q "^${ROW}" "${INI_FILE}" && perl -pi -e "s#^${ROW}##" "${INI_FILE}";
            done < <(find "${loc_php_inidir}/"*.ini);
        }
        fi;
    }
    fi;
    unset INI_FILE;
    unset ROW;
}

do_remove()
{
    local loc_php_versions loc_php_version loc_extension_dir loc_extension_file loc_php_dotver;

    if [ -n "${PVN}" ]; then
    {
        loc_php_versions="${PVN}";
    }
    else
    {
        loc_php_versions=$(find /usr/local/php*/bin/php | sort -n | egrep -o '(5|7|8|9)[0-9]+' | xargs); #'
    }
    fi;

    for loc_php_version in ${loc_php_versions};
    do
    {
        verify_php_version "${loc_php_version}";
        loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
        loc_extension_dir=$("/usr/local/php${loc_php_version}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
        loc_extension_file="${loc_extension_dir}/${EXT}.so";

        if [ "${EXT}" == "sourceguardian" ];
        then
        {
            loc_extension_file="${SOURCEGUARDIAN_DIR}/ixed.${loc_php_dotver}.lin";

            if [ -f "${loc_extension_file}" ];
            then
            {
                rm -f "${loc_extension_file}";
                echo "${BN}[OK] The extension ${EXT} for PHP ${loc_php_dotver} found! Removing it...${BF}";
            }
            else
            {
                echo "${BN}[Warning] The extension ${EXT} for PHP ${loc_php_dotver} not found! Nothing to disable...${BF}";
            }
            fi;

            do_update_ini "${loc_php_version}" "${EXT}" >/dev/null 2>&1;
        }
        else
        {
            if [ -f "${loc_extension_file}" ];
            then
            {
                rm -f "${loc_extension_file}";
                echo "${BN}[OK] The extension ${EXT} for PHP ${loc_php_dotver} found! Removing it...${BF}";
            }
            else
            {
                echo "${BN}[Warning] The extension ${EXT} for PHP ${loc_php_dotver} not found! Nothing to disable...${BF}";
            }
            fi;

            do_update_ini "${loc_php_version}" >/dev/null 2>&1;
        }
        fi;

        do_restart_webserver "${loc_php_version}";
    }
    done;
}

do_install_single()
{
    local loc_php_version;
    loc_php_version=${1:?};

    if [ "${EXT}" == "sourceguardian" ];
    then
    {
        do_install_sourceguardian;
        do_update_ini "${loc_php_version}" sourceguardian;
    }
    else
    {
        find_extension_version "${loc_php_version}";
        do_update "${loc_php_version}";
        do_update_ini "${loc_php_version}";
    }
    fi;
}

do_install()
{
    local loc_php_version loc_php_dotver;
    loc_php_version=${1};

    cd "${WORKDIR}";

    if [ -z "${loc_php_version}" ];
    then
    {
        while read -r PHPIZE
        do
        {
            loc_php_version=$(echo "${PHPIZE}" | grep -o "[0-9]*");
            loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
            verify_php_version "${loc_php_version}";
            echo "${BN}[OK] Started with PHP ${loc_php_dotver}${BF}";
            do_install_single "${loc_php_version}";
            do_restart_webserver "${loc_php_version}";
            echo "${BN}[OK] Finished with PHP ${loc_php_dotver}${BF}";
            echo; sleep 1;
        }
        done < <(find /usr/local/php*/bin/phpize);
    }
    else
    {
        loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
        verify_php_version "${loc_php_version}";
        echo "${BN}[OK] Started with PHP ${loc_php_dotver}${BF}";
        do_install_single "${loc_php_version}";
        do_restart_webserver  "${loc_php_version}";
        echo "${BN}[OK] Finished with PHP ${loc_php_dotver}${BF}";
    }
    fi;

    test -d "${PWD}" && cd "${PWD}";
}

do_status()
{
    local loc_php_versions loc_php_version loc_extension_dir loc_extension_file loc_php_dotver;

    if [ -n "${PVN}" ]; then
    {
        loc_php_versions="${PVN}";
    }
    else
    {
        loc_php_versions=$(find /usr/local/php*/bin/php | sort -n | egrep -o '(5|7|8|9)[0-9]+' | xargs); #'
    }
    fi;

    for loc_php_version in ${loc_php_versions};
    do
    {
        verify_php_version "${loc_php_version}";
        loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
        loc_extension_dir=$("/usr/local/php${loc_php_version}/bin/php" -i 2>&1 | grep "^extension_dir" | awk '{print $3}');
        loc_extension_file="${loc_extension_dir}/${EXT}.so";

        if [ "${EXT}" == "sourceguardian" ];
        then
        {
            loc_extension_file="${SOURCEGUARDIAN_DIR}/ixed.${loc_php_dotver}.lin";

            if [ -f "${loc_extension_file}" ];
            then
            {
                echo "${BN}[OK] The extension file ${loc_extension_file} for PHP ${loc_php_dotver} found!${BF}";

                IS_ENABLED=$("/usr/local/php${loc_php_version}/bin/php" -m | grep -m1 -i "^${EXT}$");

                if [ -n "${IS_ENABLED}" ]; then
                {
                    echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${loc_php_dotver}${BF} seems to be enabled!";
                    OLD_IFS="${IFS}"; IFS=$'\n';
                    while read -r ROW
                    do
                        echo "[PHP ${loc_php_dotver}] ${ROW}";
                    done < <("/usr/local/php${loc_php_version}/bin/php" -i | grep -i "^${EXT}");
                    IFS="${OLD_IFS}";
                    echo "";
                }
                else
                {
                    echo "${BN}[WARNING]${BF} The extension ${BN}${EXT}${BF} is probably not enabled for ${BN}PHP ${loc_php_dotver}${BF}! I did not detect it.";
                }
                fi;

                unset IS_ENABLED;
            }
            else
            {
                echo "${BN}[Warning] The extension file ${loc_extension_file} for PHP ${loc_php_dotver} not found${BF}";
            }
            fi;
        }
        else
        {
            if [ -f "${loc_extension_file}" ];
            then
            {
                IS_ENABLED=$("/usr/local/php${loc_php_version}/bin/php" -m | grep -m1 -i "^${EXT}$");

                if [ -n "${IS_ENABLED}" ]; then
                {
                    echo "${BN}[OK]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${loc_php_dotver}${BF} seems to be enabled!";
                    OLD_IFS="${IFS}"; IFS=$'\n';
                    while read -r ROW
                    do
                        echo "[PHP ${loc_php_dotver}] ${ROW}";
                    done < <("/usr/local/php${loc_php_version}/bin/php" -i | grep -i "^${EXT}");
                    IFS="${OLD_IFS}";
                    echo "";
                }
                else
                {
                    echo "${BN}[WARNING]${BF} The extension ${BN}${EXT}${BF} is probably not enabled for ${BN}PHP ${loc_php_dotver}${BF}! I did not detect it.";
                }
                fi;

                unset IS_ENABLED;
            }
            else
            {
                echo "${BN}[Warning]${BF} The extension ${BN}${EXT}${BF} for ${BN}PHP ${loc_php_dotver}${BF} not found!";
            }
            fi;
        }
        fi;
    }
    done;
}

do_restart_webserver()
{
    local loc_php_version loc_php_dotver loc_php_instance loc_php_mode_default loc_php_mode loc_webserver;
    loc_php_version=${1:?};
    loc_php_dotver=$(echo "${loc_php_version}" | egrep -o '(5|7|8|9)[0-9]+' | sed 's/\(.\)\(.\)/\1.\2/'); #'
    loc_php_instance=$(grep "^php[1-9]_release=${loc_php_dotver}" /usr/local/directadmin/custombuild/options.conf | cut -d_ -f1);

    if [ -n "${loc_php_instance}" ]; then
    {
        loc_php_mode_default=$(grep "^php1_mode=" /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);
        loc_php_mode=$(grep "^${loc_php_instance}_mode=" /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);
        loc_php_mode=${loc_php_mode:-$loc_php_mode_default};

        if [ "${loc_php_mode}" == "php-fpm" ]; then
        {
            echo "${BN}[INFO]${BF} Going to restart PHP-FPM ${loc_php_dotver}!";
            do_restart_service "php-fpm${loc_php_version}";
        }
        elif [ "${loc_php_mode}" == "lsphp" ]; then
        {
            echo "${BN}[INFO]${BF} Going to reload PHP ${loc_php_dotver} instances (${loc_php_mode})!";
            killall lsphp;
        }
        else
        {
            echo "${BN}[INFO]${BF} Going to restart a webserver for PHP ${loc_php_dotver} (${loc_php_mode})!";
            loc_webserver=$(grep ^webserver= /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);

            case "${loc_webserver}" in
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
        echo "${BN}[Warning]${BF} The PHP version ${BN}${loc_php_dotver}${BF} isn't managed by DirectAdmin!";
    }
    fi;
}

do_restart_service()
{
    local loc_service;
    loc_service=${1:?};
    echo "${BN}[INFO]${BF} Restarting ${loc_service}!";

    if [ -e "/bin/systemctl" ]; then
    {
        /bin/systemctl restart "${loc_service}.service";
    }
    else
    {
        /sbin/service "${loc_service}" restart;
    }
    fi;
}

do_update_script()
{
    local loc_temp_file;
    echo "${BN}[INFO]${BF} Updating the script $0 from the official repository!";
    echo "${BN}[INFO]${BF} HOME: https://github.com/poralix/directadmin-utils/!";
    loc_temp_file=$(mktemp);
    if [ -f "${loc_temp_file}" ];
    then
        curl -Ss "https://raw.githubusercontent.com/poralix/directadmin-utils/refs/heads/master/php/php-extension.sh" --output "${loc_temp_file}";
        if [ "$?" == "0" ];
        then
            cat "${loc_temp_file}" > "${SCRIPT}";
            chmod 750 "${SCRIPT}";
            echo "${BN}[INFO]${BF} Script updated OK!";
            rm -f "${loc_temp_file}";
            exit 0;
        else
            echo "${BN}[ERROR]${BF} Failed to update the script!";
        fi;
        rm -f "${loc_temp_file}";
    else
        echo "${BN}[ERROR]${BF} Failed to update the script!";
    fi;
    exit 1;
}

SCRIPT="${0}";
CMD="${1}";
EXT="${2}";
PVN="";
BETA="";
QUIET="1";
IS_CENTOS_7=$(grep -c -m1 'VERSION="7' /etc/os-release);
SOURCEGUARDIAN_DIR="/usr/local/sourceguardian";

[ -n "${CMD}" ] || do_usage;

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
        --verbose)
            QUIET=0;
        ;;
    esac;
done;

if [ -n "${BETA}" ] && [ -n "${EXT_VERSION}" ]; then
    echo "Can not use --beta and --ver= together at the same time...";
    exit 2;
fi;

case "${CMD}" in
    install)
        [ -n "${EXT}" ] || do_usage;
        do_install "${PVN}";
    ;;
    remove)
        [ -n "${EXT}" ] || do_usage;
        BETA=0;
        do_remove;
    ;;
    status)
        [ -n "${EXT}" ] || do_usage;
        BETA=0;
        do_status;
    ;;
    version)
        [ -n "${EXT}" ] || do_usage;
        BETA=0;
        do_status | grep -i 'version';
    ;;
    selfupdate)
        do_update_script;
    ;;
    *)
        BETA=0;
        do_usage;
    ;;
esac;

exit 0;
