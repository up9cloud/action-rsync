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
		die "Invalid \$MODE. Must be one of [push, pull, local]"
		;;
	esac
fi

if [ -z "$HOST" ]; then
	case "$MODE" in
	push | pull) ;;
	*)
		die "Must specify \$HOST! (Remote host)"
		;;
	esac
fi

if [ -z "$TARGET" ]; then
	die "Must specify \$TARGET! (Target folder or file. If you set it as a file, must set \$SOURCE as file too.)"
fi

if [ -z "$KEY" ]; then
	case "$MODE" in
	push | pull) ;;
	*)
		die "Must provide \$KEY! (ssh private key)"
		;;
	esac
fi

if [ -z "$USER" ]; then
	USER="root"
	case "$MODE" in
	push | pull) ;;
	*)
		log "\$USER not specified, using default: '$USER'."
		;;
	esac
fi

if [ -z "$PORT" ]; then
	PORT="22"
	case "$MODE" in
	push | pull) ;;
	*)
		log "\$PORT not specified, using default: $PORT."
		;;
	esac
fi

if [ -z "$SOURCE" ]; then
	SOURCE="./"
	log "\$SOURCE not specified, using default folder: '$SOURCE'."
fi

if [ -z "$ARGS" ]; then
	ARGS="-azv --delete --exclude=/.git/ --exclude=/.github/"
	log "\$ARGS not specified, using default rsync arguments: '$ARGS'."
fi

if [ ! -z "$ARGS_MORE" ]; then
	log "\$ARGS_MORE specified, will append to \$ARGS."
fi

if [ -z "$SSH_ARGS" ]; then
	SSH_ARGS="-p $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"
	case "$MODE" in
	push | pull) ;;
	*)
		log "\$SSH_ARGS not specified, using default: '$SSH_ARGS'."
		;;
	esac
else
	log "You spcified \$SSH_ARGS, so \$PORT will be ignored."
fi

if [ -z "$RUN_SCRIPT_ON" ]; then
	RUN_SCRIPT_ON=target
	log "\$RUN_SCRIPT_ON not specified, using default: '$RUN_SCRIPT_ON'"
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
		die "It's meaningless, you want run scripts on remote but \$MODE is local?"
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
	die "Invalid \$RUN_SCRIPT_ON, must be one of [local, remote, source, target]"
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

if [ -n "$GITHUB_WORKSPACE" ]; then
	cd $GITHUB_WORKSPACE
fi

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
		eval "$cmd_ssh" "$USER@$HOST" 'mktemp' >"$tmp_ouput"
	else
		mktemp >"$tmp_ouput"
	fi
	if [ $? -ne 0 ]; then
		die "Run 'mktemp' command failed, make sure $REAL_RUN_SCRIPT_ON server has that command!"
	fi
	local dest=$(cat "$tmp_ouput")

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
