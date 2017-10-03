# A simple script to update Directadmin from beta/stable channel per your needs:

**updateda.sh**

1. Install it:

```
cd /root/
wget https://raw.githubusercontent.com/poralix/directadmin-utils/master/core/updateda.sh
chmod 755 updateda.sh
```

2. Run to install a pre-release version:

```
./updateda.sh beta
```

3. Run to install a stable version:

```
./updateda.sh stable
```

The script will try and auto-detect UID and LID. If it fails then you will need to run 
the script with options --lid=1234 and --uid=567

```
./updateda.sh beta --lid=1234 --uid=567
```

or

```
./updateda.sh stable --lid=1234 --uid=567
```

where you will need to use 

- a real License ID instead of 1234
- a real Client ID instead of 567

You can find License ID and Client ID on a page "Licensing/Updates" in Directadmin at admin level.
