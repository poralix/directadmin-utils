#!/bin/sh
VERSION=1.2
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
                    		if [ ${CHALLENGE_TEST2} -ne 1 ]; then
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
