#!/bin/sh
set -e

# convert REDIS_CONFIG environment variables into CLI arguments
# e.g.: REDIS_CONFIG_MAXMEMORY_POLICY='allkeys-lru' => --maxmemory-policy 'allkeys-lru'
get_arguments_from_environment() {
	args=""
	for env_var in $(printenv | cut -f1 -d"=" | grep -e "^REDIS_CONFIG_")
	do
		arg_name=$(echo ${env_var#REDIS_CONFIG_} | tr "[:upper:]" "[:lower:]" | sed -e "s/_/-/g")
		arg_value=$(printenv $env_var)
		args="$args --$arg_name '$arg_value'"
	done
	echo $args
}

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	chown -R redis .
	exec su-exec redis "$0" "$@"
fi

args=$(get_arguments_from_environment)

if [ "$args" != "" ] && [ "$1" = "redis-server" ]; then
	set -- "$@" "$args"
fi

exec "$@"
