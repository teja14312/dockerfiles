#!/bin/bash

set -xe

if [ -L "$0" ] ; then
    DIR="$(dirname "$(readlink -f "$0")")" ;
else
    DIR="$(dirname "$0")" ;
fi ;

for WEB_SERVER in nginx apache; do
    # shellcheck disable=SC2043
    for PHP_VERSION in 5.6; do
        sed "s/{{PHP_VERSION}}/$PHP_VERSION/g; s/{{WEB_SERVER}}/$WEB_SERVER/g;" "${DIR}/Dockerfile.tmpl" > "${DIR}/Dockerfile-php${PHP_VERSION}-${WEB_SERVER}"
    done

done

cat "$DIR/../php/Dockerfile-nginx-phpsource" > "$DIR/Dockerfile-eol-php5.5-nginx"
# shellcheck disable=SC2016
sed '1,/^MAINTAINER /d; s/{{PHP_VERSION}}/${PHP_VERSION}/g; s/{{WEB_SERVER}}/nginx/g;' "$DIR/Dockerfile.tmpl" >> "$DIR/Dockerfile-eol-php5.5-nginx"

