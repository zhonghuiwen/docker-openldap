# Use osixia/light-baseimage
# sources: https://github.com/osixia/docker-light-baseimage
FROM osixia/light-baseimage:1.1.1
MAINTAINER Bertrand Gouny <bertrand.gouny@osixia.net>

ARG LDAP_OPENLDAP_GID
ARG LDAP_OPENLDAP_UID

# Add openldap user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# If explicit uid or gid is given, use it.
RUN if [ -z "${LDAP_OPENLDAP_GID}" ]; then groupadd -r openldap; else groupadd -r -g ${LDAP_OPENLDAP_GID} openldap; fi \
    && if [ -z "${LDAP_OPENLDAP_UID}" ]; then useradd -r -g openldap openldap; else useradd -r -g openldap -u ${LDAP_OPENLDAP_UID} openldap; fi

# Install OpenLDAP, ldap-utils and ssl-tools from baseimage and clean apt-get files
# sources: https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/add-service-available
#          https://github.com/osixia/docker-light-baseimage/blob/stable/image/service-available/:ssl-tools/download.sh
RUN echo "path-include /usr/share/doc/krb5*" >> /etc/dpkg/dpkg.cfg.d/docker && apt-get -y update \
    && /container/tool/add-service-available :ssl-tools \
	  && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       ldap-utils \
       libsasl2-modules \
       libsasl2-modules-db \
       libsasl2-modules-gssapi-mit \
       libsasl2-modules-ldap \
       libsasl2-modules-otp \
       libsasl2-modules-sql \
       openssl \
       slapd \
       krb5-kdc \
       krb5-admin-server \
       krb5-kdc-ldap \
       git \
       gcc \
       libc6-dev \
       make \
       groff \
       groff-base \
       runit \
       vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build openldap
# RUN cd /home \
#     && git clone https://github.com/zhonghuiwen/openldap \
#     && cd /home/openldap \
#     && ./configure \
#     && make depend \
#     && make \
#     #&& make test \
#     && make install \
#     && rm -rf /home/openldap \
#     && rm -rf /tmp/* /var/tmp/*

# Install custom openldap
COPY openldap-build/ /home/openldap-build/
RUN export DEBIAN_FRONTEND=noninteractive \
    && cd /home/openldap-build \
    && dpkg -i libldap-common_2.4.45+dfsg-1~bpo9+1_all.deb \
    && dpkg -i libldap-2.4-2_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    && apt --fix-broken install -y ./slapd_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    && dpkg -i ldap-utils_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    && dpkg -i ldap-utils-dbgsym_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    && dpkg -i slapd-dbgsym_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    # && apt --fix-broken install -y ./slapd-smbk5pwd_2.4.45+dfsg-1~bpo9+1_amd64.deb \
    # && dpkg -i slapd-smbk5pwd-dbgsym_2.4.45+dfsg-1~bpo9+1_amd64.deb \ 
    && apt-get install -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/openldap-build

# ENV PATH="/usr/local/libexec:${PATH}"
# RUN slapd -V

# Add service directory to /container/service
ADD service /container/service

# Use baseimage install-service script
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/install-service
RUN /container/tool/install-service

# Add default env variables
ADD environment /container/environment/99-default

# Expose default ldap and ldaps ports
EXPOSE 389 636

# Put ldap config and database dir in a volume to persist data.
# VOLUME /etc/ldap/slapd.d /var/lib/ldap
