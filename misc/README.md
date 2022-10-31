# A script to manage private_html directories on Directadmin servers              #

- private_html_symlink.sh

```
    Usage ./private_html_symlink.sh
        --list=all    - list private_html status for all domains
        --list=dirs   - list only domains with static folder for private_html
        --list=links  - list only domains with symlink for private_html
        --list=no     - list only domains without private_html at all

        --create-symlink=dirs  - Replace directory private_html with a symlink
        --create-symlink=no    - Create symlink private_html where it does not exist
```

# A script to list DirectAdmin domains

- da_domains.sh

```
Description:
    This is a script to list directadmin domains with a requested from
    DNS additional information.

Usage:
    ./da_domains.sh <options>

Options:
    --domains  - just list domains without DNS queries
    --ns       - list domains with their nameservers
    --mx       - list domains with their MX recordss
    --ipv4     - list domains with their IPv4
    --ipv6     - list domains with their IPv6
```

