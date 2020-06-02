# what is 

svnserve with Active Directory (LDAP) authentication 

https://github.com/wtnbgo/svnserve-ldap

# setup

1. saslauthd.conf and edit for your LDAP(AD) server
2. edit a svn repository's conf/svnserve.conf to use sasl
3. create a group named as the svn's realm and attach users to group

saslauthd.conf example
```
# /etc/saslauthd.conf example

# AD server adress
ldap_servers: ldap://ad.example.com

# default domain name
ldap_search_base: DC=ad,DC=example,DC=com

# authentication account
ldap_bind_dn: usermanager@ad.example.com
ldap_bind_pw: usermanager_password_!

# search group recursive for AD
ldap_filter: (&(objectClass=Person)(sAMAccountName=%u)(memberOf:1.2.840.113556.1.4.1941:=CN=%r,DC=wam-soft,DC=net))

# only group member (not recursive)
#ldap_filter: (&(objectClass=Person)(sAMAccountName=%u))
#ldap_group_dn: CN=%r,DC=ad,DC=example,DC=com
#ldap_group_attr: member

ldap_password_attr: userPassword
```

svnserve.conf example
```
# svn sample configuration 
# edit your  repository/conf/svnserve.conf

[general]

# no anonymous access
anon-access = none

## auth users have read and write access to the repository.
auth-access = write

# set AD groupname for realm
realm = mygroup

[sasl]
use-sasl = true
```

# start server

```
docker run -d \
    --name svnserve \
    --volume $(pwd)/saslauthd.conf:/etc/saslauthd.conf:ro \
    --volume ${YOUR_REPOSITORY_BASE}:/svnrepo \
    -p 3690:3690
    wtnbgo:svnserve-ldap
```

