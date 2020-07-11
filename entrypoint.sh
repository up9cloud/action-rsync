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

if [ -z "$HOST" ]; then
    die "Must specify \$HOST! (target host)"
fi

if [ -z "$TARGET" ]; then
    die "Must specify \$TARGET! (target folder)"
fi

if [ -z "$KEY" ]; then
    die "Must provide \$KEY! (ssh private key)"
fi

if [ -z "$USER" ]; then
    USER="root"
    log "\$USER not specified, using default user '$USER'."
fi

if [ -z "$PORT" ]; then
    PORT="22"
    log "\$PORT not specified, using default port $PORT."
fi

if [ -z "$SOURCE" ]; then
    SOURCE="./"
    log "\$SOURCE not specified, using default source folder '$SOURCE'."
fi

if [ -z "$ARGS" ]; then
    ARGS="-azv --delete"
    log "\$ARGS not specified, using default rsync arguments '$ARGS'."
fi

if [ -z "$SSH_ARGS" ]; then
    SSH_ARGS="-p $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"
    log "\$SSH_ARGS not specified, using default ssh arguments '$SSH_ARGS'."
else
    log "You spcified \$SSH_ARGS, so \$PORT will be ignored."
fi

# Prepare
mkdir -p "$HOME/.ssh"
echo "$KEY" > "$HOME/.ssh/key"
chmod 600 "$HOME/.ssh/key"

# Execute
cmd_ssh=$(printf "ssh -i %s %s" "$HOME/.ssh/key" "$SSH_ARGS")
cmd_rsync=$(printf "rsync %s -e '%s'" "$ARGS" "$cmd_ssh")
if [ -n "$PRE_SCRIPT" ]; then
    log ========== Pre script starting ==========
    eval "$cmd_ssh" $USER@$HOST "'""$PRE_SCRIPT""'"
    log ========== Pre script executed ==========
fi
eval "$cmd_rsync" $SOURCE $USER@$HOST:$TARGET
if [ -n "$POST_SCRIPT" ]; then
    log ========== Post script starting ==========
    eval "$cmd_ssh" $USER@$HOST "'""$POST_SCRIPT""'"
    log ========== Post script executed ==========
fi
