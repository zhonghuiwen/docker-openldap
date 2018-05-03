#!/bin/bash -e
set -o pipefail

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

# Reduce maximum number of number of open file descriptors to 1024
# otherwise slapd consumes two orders of magnitude more of RAM
# see https://github.com/docker/docker/issues/8231
ulimit -n 1024

# replace krb5.conf
cat /container/service/z-krb5/assets/krb5.conf > /etc/krb5.conf 

# start ldap server
log-helper info "Starting LDAP server for Kerberos startup..."
/usr/sbin/slapd -h "ldap://$HOSTNAME ldaps://$HOSTNAME ldapi:///" -u openldap -g openldap
# log-helper info "Waiting for OpenLDAP to start..."
# while [ ! -e /run/slapd/slapd.pid ]; do sleep 0.1; done

# use the kdb5_ldap_util utility to create the realm:
log-helper info "Creating kerberos realm..."
kdb5_ldap_util -D  cn=admin,dc=example,dc=org  create -subtrees \
dc=example,dc=org -r EXAMPLE.ORG -s -H ldapi:// -containerref 'cn=krbContainer,dc=example,dc=org' -w admin -P admin

# Create a stash of the password used to bind to the LDAP server. 
# This password is used by the ldap_kdc_dn and ldap_kadmin_dn options in /etc/krb5.conf:
log-helper info "Creating stash of password for ldap_kdc..."
echo 'admin
admin
admin' | kdb5_ldap_util -D  cn=admin,dc=example,dc=org stashsrvpw -f /etc/krb5kdc/service.keyfile cn=admin,dc=example,dc=org

# Start the Kerberos KDC and admin server:
log-helper info "Starting Kerberos KDC and admin server..."
service krb5-kdc start
service krb5-admin-server start

# Add LDAP server to kerberos
log-helper info "Adding LDAP access to kerberos..."
{ echo addprinc -randkey ldap/$HOSTNAME;
  echo ktadd -k /etc/krb5.keytab ldap/$HOSTNAME;
} | kadmin.local

chgrp openldap /etc/krb5.keytab
chmod 640 /etc/krb5.keytab

# stop OpenLDAP
log-helper info "Stop OpenLDAP..."

SLAPD_PID=$(cat /run/slapd/slapd.pid)
kill -15 $SLAPD_PID
while [ -e /proc/$SLAPD_PID ]; do sleep 0.1; done # wait until slapd is terminated

exit 0