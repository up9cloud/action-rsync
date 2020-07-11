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
    ARGS="-azv --delete --exclude=/.git/"
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

if [ -n "$GITHUB_WORKSPACE"  ]; then
    cd $GITHUB_WORKSPACE
fi

# Execute
cmd_ssh=$(printf "ssh -i %s %s" "$HOME/.ssh/key" "$SSH_ARGS")
cmd_rsync=$(printf "rsync %s -e '%s'" "$ARGS" "$cmd_ssh")
if [ -n "$PRE_SCRIPT" ]; then
    log ========== Pre script starting ==========
    eval "$cmd_ssh" $USER@$HOST 'mktemp' > /tmp/target_mktemp_output
    if [ $? -ne 0 ]; then
        die "Using \$PRE_SCRIPT, target server must support 'mktemp' command"
    fi
    target_pre_file_path=`cat /tmp/target_mktemp_output`
    local_pre_file_path=`mktemp`
    echo -e "$PRE_SCRIPT" > $local_pre_file_path
    eval "$cmd_rsync" $local_pre_file_path $USER@$HOST:$target_pre_file_path
    log ========== Pre script sent ==========
    eval "$cmd_ssh" $USER@$HOST "sh $target_pre_file_path"
    log ========== Pre script executed ==========
    eval "$cmd_ssh" $USER@$HOST "rm $target_pre_file_path"
    log ========== Pre script removed ==========
fi
eval "$cmd_rsync" $SOURCE $USER@$HOST:$TARGET
if [ -n "$POST_SCRIPT" ]; then
    log ========== Post script starting ==========
    eval "$cmd_ssh" $USER@$HOST 'mktemp' > /tmp/target_mktemp_output
    if [ $? -ne 0 ]; then
        die "Using \$POST_SCRIPT, target server must support 'mktemp' command"
    fi
    target_post_file_path=`cat /tmp/target_mktemp_output`
    local_post_file_path=`mktemp`
    echo -e "$POST_SCRIPT" > $local_post_file_path
    eval "$cmd_rsync" $local_post_file_path $USER@$HOST:$target_post_file_path
    log ========== Post script sent ==========
    eval "$cmd_ssh" $USER@$HOST "sh $target_post_file_path"
    log ========== Post script executed ==========
    eval "$cmd_ssh" $USER@$HOST "rm $target_post_file_path"
    log ========== Post script removed ==========
fi
