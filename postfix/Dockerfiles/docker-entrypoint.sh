#!/usr/bin/env sh

[ -f "/etc/postfix/conf.d/aliases" ] && postalias /etc/postfix/conf.d/aliases
[ -f "/etc/postfix/conf.d/virtual" ] && postmap /etc/postfix/conf.d/virtual
[ -f "/etc/postfix/conf.d/sasl_passwd" ] && postmap /etc/postfix/conf.d/sasl_passwd

/usr/sbin/postfix start-fg
