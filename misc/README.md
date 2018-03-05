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
