#!/bin/sh
set -e

function log() {
	if [ "$VERBOSE" == "true" ]; then
		echo [action-rsync] "$@"
	fi
}
function die() {
	echo [action-rsync] "$@" 1>&2
	exit 1
}
function setup_keys() {
	local prefix="$1"
	K_VERBOSE="\$${prefix}VERBOSE"
	K_MODE="\$${prefix}MODE"
	K_HOST="\$${prefix}HOST"
	K_TARGET="\$${prefix}TARGET"
	K_KEY="\$${prefix}KEY"
	K_USER="\$${prefix}USER"
	K_PORT="\$${prefix}PORT"
	K_SOURCE="\$${prefix}SOURCE"
	K_ARGS="\$${prefix}ARGS"
	K_ARGS_MORE="\$${prefix}ARGS_MORE"
	K_SSH_ARGS="\$${prefix}SSH_ARGS"
	K_RUN_SCRIPT_ON="\$${prefix}RUN_SCRIPT_ON"
	K_PRE_SCRIPT="\$${prefix}PRE_SCRIPT"
	K_POST_SCRIPT="\$${prefix}POST_SCRIPT"
}
# Defaults
setup_keys

# Drone CI
if [ -n "$PLUGIN_VERBOSE" ]; then
	VERBOSE="$PLUGIN_VERBOSE"
fi
if [ -n "$PLUGIN_MODE" ]; then
	MODE="$PLUGIN_MODE"
fi
if [ -n "$PLUGIN_HOST" ]; then
	HOST="$PLUGIN_HOST"
fi
if [ -n "$PLUGIN_TARGET" ]; then
	TARGET="$PLUGIN_TARGET"
	# Because $TARGET must be set, so we set keys here
	setup_keys "PLUGIN_"
fi
if [ -n "$PLUGIN_KEY" ]; then
	KEY="$PLUGIN_KEY"
fi
if [ -n "$PLUGIN_USER" ]; then
	USER="$PLUGIN_USER"
fi
if [ -n "$PLUGIN_PORT" ]; then
	PORT="$PLUGIN_PORT"
fi
if [ -n "$PLUGIN_SOURCE" ]; then
	SOURCE="$PLUGIN_SOURCE"
fi
if [ -n "$PLUGIN_ARGS" ]; then
	ARGS="$PLUGIN_ARGS"
fi
if [ -n "$PLUGIN_ARGS_MORE" ]; then
	ARGS_MORE="$PLUGIN_ARGS_MORE"
fi
if [ -n "$PLUGIN_SSH_ARGS" ]; then
	SSH_ARGS="$PLUGIN_SSH_ARGS"
fi
if [ -n "$PLUGIN_RUN_SCRIPT_ON" ]; then
	RUN_SCRIPT_ON="$PLUGIN_RUN_SCRIPT_ON"
fi
if [ -n "$PLUGIN_PRE_SCRIPT" ]; then
	PRE_SCRIPT="$PLUGIN_PRE_SCRIPT"
fi
if [ -n "$PLUGIN_POST_SCRIPT" ]; then
	POST_SCRIPT="$PLUGIN_POST_SCRIPT"
fi

# Github action
if [ -n "$GITHUB_WORKSPACE" ]; then
	cd $GITHUB_WORKSPACE
fi

if [ -z "$VERBOSE" ]; then
	VERBOSE=false
fi

if [ -z "$MODE" ]; then
	MODE=push
else
	MODE=$(echo "$MODE" | tr '[:upper:]' '[:lower:]')

	case "$MODE" in
	push | pull | local) ;;
	*)
		die "Invalid $K_MODE. Must be one of [push, pull, local]"
		;;
	esac
fi

if [ -z "$HOST" ]; then
	case "$MODE" in
	push | pull)
		die "Must specify $K_HOST! (Remote host)"
		;;
	esac
fi

if [ -z "$TARGET" ]; then
	die "Must specify $K_TARGET! (Target folder or file. If you set it as a file, must set $K_SOURCE as file too.)"
fi

if [ -z "$KEY" ]; then
	case "$MODE" in
	push | pull)
		die "Must provide $K_KEY! (ssh private key)"
		;;
	esac
fi

if [ -z "$USER" ]; then
	USER="root"
	case "$MODE" in
	push | pull)
		log "$K_USER not specified, using default: '$USER'."
		;;
	esac
fi

if [ -z "$PORT" ]; then
	PORT="22"
	case "$MODE" in
	push | pull)
		log "$K_PORT not specified, using default: $PORT."
		;;
	esac
fi

if [ -z "$SOURCE" ]; then
	SOURCE="./"
	log "$K_SOURCE not specified, using default folder: '$SOURCE'."
fi

if [ -z "$ARGS" ]; then
	ARGS="-azv --delete --exclude=/.git/ --exclude=/.github/"
	log "$K_ARGS not specified, using default rsync arguments: '$ARGS'."
fi

if [ ! -z "$ARGS_MORE" ]; then
	log "$K_ARGS_MORE specified, will append to $K_ARGS."
fi

if [ -z "$SSH_ARGS" ]; then
	SSH_ARGS="-p $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"
	case "$MODE" in
	push | pull)
		log "$K_SSH_ARGS not specified, using default: '$SSH_ARGS'."
		;;
	esac
else
	log "You spcified $K_SSH_ARGS, so $K_PORT will be ignored."
fi

if [ -z "$RUN_SCRIPT_ON" ]; then
	RUN_SCRIPT_ON=target
	log "$K_RUN_SCRIPT_ON not specified, using default: '$RUN_SCRIPT_ON'"
else
	RUN_SCRIPT_ON=$(echo "$RUN_SCRIPT_ON" | tr '[:upper:]' '[:lower:]')
fi

case "$RUN_SCRIPT_ON" in
local)
	REAL_RUN_SCRIPT_ON="$RUN_SCRIPT_ON"
	;;
remote)
	REAL_RUN_SCRIPT_ON="$RUN_SCRIPT_ON"
	if [ "$MODE" == "local" ]; then
		die "It's meaningless, you want run scripts on remote but $K_MODE is local?"
	fi
	;;
source)
	if [ "$MODE" == "local" ]; then
		REAL_RUN_SCRIPT_ON=local
	elif [ "$MODE" == "push" ]; then
		REAL_RUN_SCRIPT_ON=local
	else
		REAL_RUN_SCRIPT_ON=remote
	fi
	;;
target)
	if [ "$MODE" == "local" ]; then
		REAL_RUN_SCRIPT_ON=local
	elif [ "$MODE" == "push" ]; then
		REAL_RUN_SCRIPT_ON=remote
	else
		REAL_RUN_SCRIPT_ON=local
	fi
	;;
*)
	die "Invalid $K_RUN_SCRIPT_ON, must be one of [local, remote, source, target]"
	;;
esac

# Prepare
case "$MODE" in
push | pull)
	mkdir -p "$HOME/.ssh"
	echo "$KEY" >"$HOME/.ssh/key"
	chmod 600 "$HOME/.ssh/key"
	;;
esac

cmd_ssh=$(printf "ssh -i %s %s" "$HOME/.ssh/key" "$SSH_ARGS")
case "$MODE" in
push | pull)
	cmd_rsync=$(printf "rsync %s %s -e '%s'" "$ARGS" "$ARGS_MORE" "$cmd_ssh")
	;;
local)
	cmd_rsync=$(printf "rsync %s %s" "$ARGS" "$ARGS_MORE")
	;;
esac
case "$REAL_RUN_SCRIPT_ON" in
local)
	cmd_rsync_script=$(printf "rsync -av")
	;;
remote)
	cmd_rsync_script=$(printf "rsync -avz -e '%s'" "$cmd_ssh")
	;;
esac

run_script() {
	local name="$1"
	local src="$2"

	log "========== $name starting =========="
	local tmp_output=/tmp/target_mktemp_output
	if [ "$REAL_RUN_SCRIPT_ON" == "remote" ]; then
		eval "$cmd_ssh" "$USER@$HOST" 'mktemp' >"$tmp_output"
	else
		mktemp >"$tmp_output"
	fi
	if [ $? -ne 0 ]; then
		die "Run 'mktemp' command failed, make sure $REAL_RUN_SCRIPT_ON server has that command!"
	fi
	local dest=$(cat "$tmp_output")

	if [ "$REAL_RUN_SCRIPT_ON" == "remote" ]; then
		eval "$cmd_rsync_script" "$src" "$USER@$HOST:$dest"
	else
		eval "$cmd_rsync_script" "$src" "$dest"
	fi
	log "========== $name sent =========="
	if [ "$REAL_RUN_SCRIPT_ON" == "remote" ]; then
		eval "$cmd_ssh" "$USER@$HOST" "sh $dest"
	else
		sh "$dest"
	fi
	log "========== $name executed =========="
	if [ "$REAL_RUN_SCRIPT_ON" == "remote" ]; then
		eval "$cmd_ssh" "$USER@$HOST" "rm $dest"
	else
		rm "$dest"
	fi
	log "========== $name removed =========="
}

# Execute
if [ -n "$PRE_SCRIPT" ]; then
	pre_src=$(mktemp)
	echo -e "$PRE_SCRIPT" >"$pre_src"
	run_script "Pre script" "$pre_src"
fi
case "$MODE" in
push)
	eval "$cmd_rsync" "$SOURCE" "$USER@$HOST:$TARGET"
	;;
pull)
	eval "$cmd_rsync" "$USER@$HOST:$SOURCE" "$TARGET"
	;;
local)
	eval "$cmd_rsync" "$SOURCE" "$TARGET"
	;;
esac
if [ -n "$POST_SCRIPT" ]; then
	post_src=$(mktemp)
	echo -e "$POST_SCRIPT" >"$post_src"
	run_script "Post script" "$post_src"
fi
