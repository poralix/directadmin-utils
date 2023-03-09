#!/bin/bash
################################################################################
#                                                                              #
# A script to update Directadmin from official channels                        #
#   Based on:                                                                  #
#      https://docs.directadmin.com/directadmin/general-usage/updating-da.html #
#                                                                              #
################################################################################
#                                                                              #
#      Version:  0.1 (Fri Mar 10 00:01:19 +07 2023)                            #
#      Last modified: Fri Mar 10 00:01:19 +07 2023                             #
#      Site: www.poralix.com  E-mail: support@poralix.com                      #
#                                                                              #
################################################################################

usage()
{
    echo "
Usage:
    $0 <channel>

Channels:
    'alpha', 'beta', 'current', 'stable' or EOL channels: 'freebsd', 'rhel6', 'debian8', 'debian9'
";
}

# can be one of: alpha, beta, current, stable or EOL channels: freebsd, rhel6, debian8, debian9
CHANNEL="";

case "${1}" in
    alpha|beta|current|stable|freebsd|rhel6|debian8|debian9)
        CHANNEL="${1}";
        echo "Going to install DirectAdmin from a ${CHANNEL} channel";
    ;;
    --help|--usage)
        usage;
        exit 0;
    ;;
    *)
        usage;
        exit 1;
    ;;
esac;

# can be: linux_amd64, linux_arm64, freebsd_amd64
OS_SLUG="linux_amd64";

# can be commit hash literal value if you want specific build to be installed
COMMIT=$(dig +short -t txt "$CHANNEL-version.directadmin.com" | sed 's|.*commit=\([0-9a-f]*\).*|\1|') #';

# creates download package name from the variables above
FILE="directadmin_${COMMIT}_${OS_SLUG}.tar.gz";

test -f "/root/${FILE}" && rm -f "/root/${FILE}";

# downloads given directadmin build into /root dir
curl --location --progress-bar --connect-timeout 10 "https://download.directadmin.com/${FILE}" --output "/root/${FILE}";

if [ -f "/root/${FILE}" ];
then
    # extracts downloaded package to /usr/local/directadmin
    tar -xzf "/root/${FILE}" -C /usr/local/directadmin && rm -f "/root/${FILE}";

    # runs post-upgrade permission fix step
    /usr/local/directadmin/directadmin permissions || true;

    # runs other post upgrade fixes
    /usr/local/directadmin/scripts/update.sh;

    # restarts directadmin
    service directadmin restart;
else
    echo "Failed to download a file";
fi;

# print out a version
/usr/local/directadmin/directadmin version;

exit 0;
