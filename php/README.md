# Scripts for operations with PHP

- php-extension.sh 
- bulk_run_php.sh
- change_domain_phpver.sh
- test_sockets_ssl.php


# Description of php-extension.sh 

A script to install/update/remove PECL extension for installed by CustomBuild 2.x PHP versions

Written by: Alex Grebenschikov (support@poralix.com)

**IMPORTANT**: mod_php is not supported at the moment

```
Usage:

    ./php-extension.sh <command> <pecl_extension> [<options>]

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
                81, 82, 83 etc

    --verbose - show messages from configure/make operations

```

# Description of bulk_run_php.sh

A script to run code with all existing PHP versions installed by CustomBuild 2.x

```
Usage:
    ./bulk_run_php.sh <command-for-php>

Built-in commands:
    versions      - to list installed PHP versions
    full-versions - to show installed PHP versions
    build         - to re-install all installed versions (expert mode is used)
    update        - to update all installed versions (expert mode is used)
    --ini         - to show loaded ini files for PHP

Build all (beta):
    DO NOT use it for mod_php!!!
    you can specify: suphp, fastcgi, php-fpm to force the mode

Update all (beta):
    DO NOT use it for mod_php!!!
    you can specify: suphp, fastcgi, php-fpm to force the mode

Other commands:
    You can run any other command supported by PHP,
    run
        php --help
    or
        ./bulk_run_php.sh --help
    to see a list of the options.
```

# Description of change_domain_phpver.sh

The script can be used to show which PHP version is set for a domain in Directadmin.

You can use the script to change PHP version for a domain from pre-installed with Custombuild 2.0.

Example of usage:

```
# ./change_domain_phpver.sh domain.com
Domain domain.com found and is owned by the user userbob
Currently used: (no values mean defaults)
    php1_select: 5.3 as suphp (2)
    php2_select: 5.6 as suphp (1)
PHP Versions:
    1 stands for PHP (default): 5.6 as suphp
    2 stands for PHP (additional): 5.3 as suphp
You did not specified new version, terminating here...
```

Run

```
./change_domain_phpver.sh domain.com 2
```

to set the second PHP version as a default for the domain.com (in our case it's PHP 5.3).

Run

```
./change_domain_phpver.sh domain.com 1
```

to set the primary PHP version as a default for the domain.com (in our case it's PHP 5.6).

# Description of test_sockets_ssl.php

A simple PHP-script to test connections to a remote host with and/or without TLS/SSL.

Run under Document Root via HTTP/HTTPS or in a console:

```
# php test_sockets_ssl.php
<pre>
Connection to imap.gmail.com:993 without SSL  FAILED
Connection to imap.gmail.com:993 with SSL  FAILED
Connection to smtp.gmail.com:25 without SSL  FAILED
Connection to smtp.gmail.com:25 with SSL  OK
Connection to smtp.gmail.com:465 without SSL  FAILED
Connection to smtp.gmail.com:465 with SSL  FAILED
Connection to smtp.gmail.com:587 without SSL  FAILED
Connection to smtp.gmail.com:587 with SSL  OK
</pre>
```
