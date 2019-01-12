#!/bin/sh
VERSION=1.2.patched
###############################################################################
#                                                                             #
#          Automatically setup LetsEncrypt SSL for *all* domains              #
#               that do not currently have a certificate                      #
#                                                                             #
###############################################################################
#                                                                             #
#                  Original script written by Directadmin                     #
#               https://help.directadmin.com/item.php?id=675                  #
#   http://files.directadmin.com/services/all/letsencrypt/autoletsencrypt.sh  #
#                                                                             #
###############################################################################
#                                                                             #
#               Patched by Poralix to add mail subdomain into certs           #
#      Last modified: Sat Jan 12 15:04:00 +07 2019 (support@poralix.com)      #
#                                                                             #
###############################################################################

WELLKNOWN_PATH="/var/www/html/.well-known/acme-challenge"
TIMESTAMP=`date +%s`
CURL=/usr/local/bin/curl
if [ ! -x ${CURL} ]; then
        CURL=/usr/bin/curl
fi

challenge_check() {
        if [ ! -d ${WELLKNOWN_PATH} ]; then
                mkdir -p ${WELLKNOWN_PATH}
        fi
        touch ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}
        #Checking if http://www.domain.com/.well-known/acme-challenge/letsencrypt_${TIMESTAMP} is available
		if ! ${CURL} ${CURL_OPTIONS} -k -I -L -X GET http://${1}/.well-known/acme-challenge/letsencrypt_${TIMESTAMP} 2>/dev/null | grep -m1 -q 'HTTP.*200'; then
                echo 1
        else
                echo 0
        fi
        rm -f ${WELLKNOWN_PATH}/letsencrypt_${TIMESTAMP}
}

for u in `ls /usr/local/directadmin/data/users`; do
{
          for d in `cat /usr/local/directadmin/data/users/$u/domains.list`; do
          {
                    if [ ! -e /usr/local/directadmin/data/users/$u/domains/$d.cert ] && [ -s /usr/local/directadmin/data/users/$u/domains/$d.conf ]; then
                    	CHALLENGE_TEST=`challenge_check $d`
                    	if [ ${CHALLENGE_TEST} -ne 1 ]; then
                    		CHALLENGE_TEST2=`challenge_check www.$d`
                    		CHALLENGE_TEST3=`challenge_check mail.$d`
                    		if [ ${CHALLENGE_TEST2} -ne 1 ] && [ ${CHALLENGE_TEST3} -ne 1 ]; then
                    			/usr/local/directadmin/scripts/letsencrypt.sh request ${d},www.${d},mail.${d} 4096
                    		elif [ ${CHALLENGE_TEST2} -ne 1 ]; then
                    			/usr/local/directadmin/scripts/letsencrypt.sh request ${d} 4096
                    		else
                    			/usr/local/directadmin/scripts/letsencrypt.sh request_single ${d} 4096
                    		fi
						fi
					fi
					if [ -e /usr/local/directadmin/data/users/$u/domains/$d.cert ]; then
						REWRITE=false
								if ! grep -m1 -q '^ssl=ON' /usr/local/directadmin/data/users/$u/domains/$d.conf; then
									perl -pi -e 's|^ssl\=OFF|ssl=ON|g' /usr/local/directadmin/data/users/$u/domains/$d.conf								
									REWRITE=true
								fi
								if ! grep -m1 -q '^SSLCACertificateFile=' /usr/local/directadmin/data/users/$u/domains/$d.conf; then
									perl -pi -e "s|^UseCanonicalName=|SSLCACertificateFile=/usr/local/directadmin/data/users/$u/domains/$d.cacert\nSSLCertificateFile=/usr/local/directadmin/data/users/$u/domains/$d.cert\nSSLCertificateKeyFile=/usr/local/directadmin/data/users/$u/domains/$d.key\nUseCanonicalName=|g" /usr/local/directadmin/data/users/$u/domains/$d.conf
									REWRITE=true
								fi
								if ${REWRITE}; then
									echo "action=rewrite&value=httpd&user=$u" >> /usr/local/directadmin/data/task.queue
								fi
					fi
          }
          done;
}
done;
exit 0
