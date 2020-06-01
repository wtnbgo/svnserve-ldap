# what is 

svnserve with Active Directory (LDAP) authentication 

# setup

1. copy saslauthd.conf.exsample to saslauthd.conf and edit for your LDAP(AD) server
2. edit a svn repository's conf/svnserve.conf to use sasl
3. create a group named as the svn's realm and attach users to group

# start server

```
docker run -d \
    --name svnserve \
    --volume $(pwd)/saslauthd.conf:/etc/saslauthd.conf:ro \
    --volume ${YOUR_REPOSITORY_BASE}:/svnrepo \
    -p 3690:3690
    wtnbgo:svnserve-ldap
```

