FROM alpine:3.12

MAINTAINER Go Watanabe <wtnbgo@gmail.com>

LABEL org.label-schema.name="svnserve-ldap" \
        org.label-schema.vendor="wtnbgo" \
        org.label-schema.description="Docker image svnserve with AD(LDAP) authentication" \
        org.label-schema.vcs-url="https://github.com/wtnbgo/svnserve-ldap" \
        org.label-schema.version="1.0" \
        org.label-schema.license="MIT"

RUN apk update && apk upgrade

# install runit
# from https://github.com/dockage/alpine-runit
# MAINTAINER Mohammad Abdoli Rad <m.abdolirad@gmail.com>

ENV SERVICE_AVAILABLE_DIR=/etc/sv \
    SERVICE_ENABLED_DIR=/service

ENV SVDIR=${SERVICE_ENABLED_DIR} \
    SVWAIT=7

ADD https://rawgit.com/dockage/runit-scripts/master/scripts/installer /opt/

RUN apk --no-cache add runit \
    && mkdir -p ${SERVICE_AVAILABLE_DIR} ${SERVICE_ENABLED_DIR} \
    && chmod +x /opt/installer \
    && sync \
    && /opt/installer \
    && rm -rf /var/cache/apk/* /opt/installer

# compile saslauthd with ldap
# from https://github.com/dweomer/dockerfiles-saslauthd
# MAINTAINER Jacob Blain Christen <mailto:dweomer5@gmail.com, https://github.com/dweomer, https://twitter.com/dweomer>

RUN set -x \
 && mkdir -p /srv/saslauthd.d /tmp/cyrus-sasl /var/run/saslauthd \
 && export BUILD_DEPS=" \
    build-base \
	db-dev \
	libressl-dev \
	heimdal-dev \
    openldap-dev \
	automake \
	autoconf \
	libtool \
    curl \
    tar \
    " \
 && apk update && apk upgrade \
 && apk add --update --no-cache --update-cache ${BUILD_DEPS} \
        cyrus-sasl \
        libldap \
 && curl -fL https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz -o /tmp/cyrus-sasl.tgz \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-as_needed.patch -o /tmp/cyrus-sasl-patch0 \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-autotools_fixes.patch  -o /tmp/cyrus-sasl-patch1 \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-avoid_pic_overwrite.patch  -o /tmp/cyrus-sasl-patch2 \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-doc_build_fix.patch -o /tmp/cyrus-sasl-patch3 \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.27-gss_c_nt_hostbased_service.patch  -o /tmp/cyrus-sasl-patch4 \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/CVE-2019-19906.patch -o /tmp/cyrus-sasl-patch5 \
 && tar -xzf /tmp/cyrus-sasl.tgz --strip=1 -C /tmp/cyrus-sasl \
 && cd /tmp/cyrus-sasl \
 && patch -p1 -i /tmp/cyrus-sasl-patch0 \
 && patch -p1 -i /tmp/cyrus-sasl-patch1 \
 && patch -p1 -i /tmp/cyrus-sasl-patch2 \
 && patch -p1 -i /tmp/cyrus-sasl-patch3 \
 && patch -p1 -i /tmp/cyrus-sasl-patch4 \
 && patch -p1 -i /tmp/cyrus-sasl-patch5 

RUN cd /tmp/cyrus-sasl \
 && autoreconf -f -i \
 && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-anon \
		--disable-java \
        --enable-plain \
        --enable-cram \
        --enable-digest \
        --enable-ldapdb \
        --enable-login \
		--disable-gssapi \
        --disable-ntlm \
		--disable-krb4 \
        --disable-otp \
        --with-devrandom=/dev/urandom \
        --with-ldap=/usr \
        --with-saslauthd=/var/run/saslauthd \
         && make -j1 \
         && make -j1 install

# Clean up build-time packages
RUN apk del --purge ${BUILD_DEPS} \
# Clean up anything else
 && rm -fr \
    /tmp/* \
    /var/tmp/* \
    /var/cache/apk/*

VOLUME ["/var/run/saslauthd"]

# entry saslauthd to runit service
COPY saslauthd.sh /service/saslauthd/run
RUN chmod +x /service/saslauthd/run

# install subversion
RUN apk --update --no-cache add subversion && \
    rm -rf /var/cache/apk/*

# subversion sasl config
COPY svn.conf /etc/sasl2/svn.conf

# entry svnserve to runit service
COPY svnserve.sh /service/svnserve/run
RUN chmod +x /service/svnserve/run

# start runint
CMD ["/sbin/runit-init"]