#!/bin/bash
#----------------------------------------------------------------------
# Description: Majordomo Mailings Lists Digest and Archives clearing
# Author: Alexey S Grebenshchikov (support@poralix.com)
# Last modified: Wed May 23 00:14:53 +07 2018
# Created at: Wed Oct 22 15:40:22 NOVST 2008
#
#----------------------------------------------------------------------
# Versions:
#            0.2 $ Wed May 23 00:14:53 +07 2018
#----------------------------------------------------------------------

main()
{
    VIRTUAL_DIR="/etc/virtual";
    for i in `ls ${VIRTUAL_DIR}`;
    do
        if  [ -d "${VIRTUAL_DIR}/${i}" ];
        then
            # STEP 1
            DIGESTS_DIR="${VIRTUAL_DIR}/${i}/majordomo/digests";
            if [ -d "${DIGESTS_DIR}" ];
            then
                for j in `ls ${DIGESTS_DIR}`;
                do
                    echo "[`date`] Clearing ${DIGESTS_DIR}/${j}/";
                    find ${DIGESTS_DIR}/${j} -mtime +2 -type f -exec rm {} \;
                done;
            fi;

            # STEP 2
            ARCHIVES_DIR="${VIRTUAL_DIR}/${i}/majordomo/lists";
            if [ -d  "${ARCHIVES_DIR}" ]; 
            then
                for j in `ls ${ARCHIVES_DIR} | grep "\-digest.archive"`
                do
                    echo "[`date`] Clearing ${ARCHIVES_DIR}/${j}/";
                    find ${ARCHIVES_DIR}/${j} -mtime +2 -type f -exec rm {} \;
                done;
            fi;
        fi;
    done;
}

#/var/log/majordomo_clear_digest.log
main;

exit 0;
