#!/bin/env bash

ere_quote() {
  # this escapes regex reserved characters
  # it also escapes / for subsequent use with sed
  sed 's/[][\/\.|$(){}?+*^]/\\&/g' <<< "$*"
}

DOMAIN=$(grep "^DOMAIN" .env | awk -F '=' '{print $2}')
SMTP_RELAY_HOST=$(grep "^SMTP_RELAY_HOST" .env | awk -F '=' '{print $2}')
SMTP_RELAY_USERNAME=$(grep "^SMTP_RELAY_USERNAME" .env | awk -F '=' '{print $2}')
SMTP_RELAY_PASSWORD=$(grep "^SMTP_RELAY_PASSWORD" .env | awk -F '=' '{print $2}')
SMTP_RELAY_MAILFROM=$(grep "^SMTP_RELAY_MAILFROM" .env | awk -F '=' '{print $2}')
SUBDOMAIN=$(grep "^SUBDOMAIN" .env | awk -F '=' '{print $2}')
PG_USERNAME=$(grep "^POSTGRES_USER" .env | awk -F '=' '{print $2}')
PG_PASSWORD=$(grep "^POSTGRES_PASSWORD" .env | awk -F '=' '{print $2}')

if [ -z "$SUBDOMAIN" ]; then
  SUBDOMAIN="app"
fi

sed -e "s/domain.tld/${DOMAIN}/g" ./acme.sh/www/.well-known/mta-sts.txt.tpl >./acme.sh/www/.well-known/mta-sts.txt

if [ ! -f ./nginx/conf.d/default.conf ]; then
  sed -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" -e "s/domain.tld/${DOMAIN}/g" ./nginx/conf.d/default-init.conf.tpl > ./nginx/conf.d/default.conf
  sed -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" -e "s/domain.tld/${DOMAIN}/g" ./nginx/conf.d/default.conf.tpl > ./nginx/conf.d/nginx
fi

sed -e "s/app.domain.tld/${SUBDOMAIN}.${DOMAIN}/g" -e "s/domain.tld/${DOMAIN}/g" -e "s/smtp.relay.host/${SMTP_RELAY_HOST}/g" ./postfix/conf.d/main.cf.tpl > ./postfix/conf.d/main.cf

if [ ! -f ./postfix/conf.d/virtual ]; then
  sed -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/virtual.tpl > ./postfix/conf.d/virtual
fi
if [ ! -f ./postfix/conf.d/virtual-regexp ]; then
  sed -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/virtual-regexp.tpl > ./postfix/conf.d/virtual-regexp
fi
if [ ! -f ./postfix/conf.d/sasl_passwd ]; then
  sed -e "s/smtp.relay.host/${SMTP_RELAY_HOST}/g" -e "s/smtp-username/${SMTP_RELAY_USERNAME}/g" -e "s/smtp-password/${SMTP_RELAY_PASSWORD}/g" ./postfix/conf.d/sasl_passwd.cf.tpl > ./postfix/conf.d/sasl_passwd
fi
if [ ! -f ./postfix/conf.d/canonical-sender ]; then
  sed -e "s/smtp-relay-mailfrom/${SMTP_RELAY_MAILFROM}/g" ./postfix/conf.d/canonical-sender.tpl > ./postfix/conf.d/canonical-sender
fi

sed -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-relay-domains.cf.tpl >./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-relay-domains.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-relay-domains.cf

sed -e "s/myuser/${PG_USERNAME}/g" ./postfix/conf.d/pgsql-transport-maps.cf.tpl >./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/mypassword/$(ere_quote ${PG_PASSWORD})/g" ./postfix/conf.d/pgsql-transport-maps.cf
sed -i -e "s/domain.tld/${DOMAIN}/g" ./postfix/conf.d/pgsql-transport-maps.cf

docker compose up --detach $@
