#!/usr/bin/env bash
#
# by Alex Grebenschikov (www.poralix.com)
#
VER="1.0.1";
INSTALL_TO="/usr";

URL="https://www.openssl.org/source/old/${VER}/openssl-${VER}u.tar.gz"
DIR_TO="/usr/local/src";
SAVE_TO="${DIR_TO}/openssl-${VER}-latest.tar.gz";

wget ${URL} -O ${SAVE_TO};
tar -zxvf ${SAVE_TO} -C ${DIR_TO};

cd ${DIR_TO};
DIR=`ls -1d openssl-${VER}*/ | tail -1`;
cd ${DIR};

./config --prefix=${INSTALL_TO} no-ssl2 no-ssl3 zlib-dynamic -fPIC shared;
make depend && make install;

c=`grep "${INSTALL_TO}/lib" /etc/ld.so.conf -c`;
if [ "${c}" == "0" ]; then
     echo "${INSTALL_TO}/lib" >> /etc/ld.so.conf;
fi;
ldconfig

exit 0;
