#!/bin/sh

. entrypoint-common.sh

entrypoint-hooks.sh

migrate_uid munin "$MUNIN_USER_UID"

envsubst < "/usr/local/munin/munin.conf.docker" > "/usr/local/munin/munin.conf"

chown -R munin:www-data \
    /usr/local/munin/data \
    /usr/local/munin/logs \
    /var/cache/fontconfig \
    /var/run/munin \

entrypoint-post-hooks.sh

exec "$@"
