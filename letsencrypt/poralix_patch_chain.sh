#!/bin/bash
#----------------------------------------------------------------------
# Description: A script to force Let's Encrypt to use DST Root CA X3
#----------------------------------------------------------------------
# Author: Alex Grebenschikov, www.poralix.com
# Created at: Fri Dec 16 17:45:36 +07 2022
# Last modified: Fri Dec 16 17:45:36 +07 2022
# Version: 0.1 $ Fri Dec 16 17:45:36 +07 2022
#----------------------------------------------------------------------
# Copyright (c) 2022 Alex Grebenschikov, www.poralix.com

# INSTALLATION:
# =====================================================================
# RUN AS ROOT:
# =====================================================================
# mkdir -p /usr/local/directadmin/custombuild/custom/hooks/letsencrypt/post/
# cd /usr/local/directadmin/custombuild/custom/hooks/letsencrypt/post/
#
# COPY/MOVE FILE TO THE CREATED FOLDER AND RUN:
#
# wget -O poralix_patch_chain.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/letsencrypt/poralix_patch_chain.sh
# chmod 750 poralix_patch_chain.sh
# /usr/local/directadmin/custombuild/build letsencrypt
#

echo "";
echo "Running patch script from Poralix:";
echo "";

set -x;
\cp -fp /usr/local/directadmin/scripts/letsencrypt.sh{,~orig};
perl -pi -e "s/ISRG Root X1/DST Root CA X3/" /usr/local/directadmin/scripts/letsencrypt.sh;
