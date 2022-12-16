# A script to force Let's Encrypt to use DST Root CA X3

Here is a patch for Let's Encrypt script from DirectAdmin to force it to use "DST Root CA X3" instead of "ISRG Root X1" when issuing SSL certificates.

For installation run as root:

```
mkdir -p /usr/local/directadmin/custombuild/custom/hooks/letsencrypt/post/
cd /usr/local/directadmin/custombuild/custom/hooks/letsencrypt/post/
wget -O poralix_patch_chain.sh https://raw.githubusercontent.com/poralix/directadmin-utils/master/letsencrypt/poralix_patch_chain.sh
chmod 750 poralix_patch_chain.sh
/usr/local/directadmin/custombuild/build letsencrypt
```


# let's encrypt patch for VERSION=1.0.18 letsencrypt.sh

Having 10-20-30... domains (and more) in ca.san_config is a challenge to get them verified at once. This patch will give you a re-try on challenge verification.

# Install

```
cd /usr/local/directadmin/scripts
cp -p letsencrypt.sh letsencrypt_poralix.sh
wget -O ./letsencrypt_poralix.patch https://raw.githubusercontent.com/poralix/directadmin-utils/master/letsencrypt/letsencrypt_poralix.patch
patch ./letsencrypt_poralix.sh -i letsencrypt_poralix.patch
```

# Example:

```
Getting challenge for mail.poralix.com from acme-server...
Challenge error: HTTP/1.1 100 Continue
Expires: Tue, 11 Apr 2017 04:21:31 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache

HTTP/1.1 500 Internal Server Error
Server: AkamaiGHost
Mime-Version: 1.0
Content-Type: text/html
Content-Length: 176
Expires: Tue, 11 Apr 2017 04:21:31 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache
Date: Tue, 11 Apr 2017 04:21:31 GMT
Connection: close

<HTML><HEAD><TITLE>Error</TITLE></HEAD><BODY>
An error occurred while processing your request.<p>
Reference&#32;&#35;179&#46;8c346d68&#46;1491884491&#46;2960089
</BODY></HTML>.

Do you want to retry (yes/no): yes
Waiting for domain verification...
Challenge is valid.
```

That's it!
