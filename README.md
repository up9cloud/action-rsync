# action-rsync ![.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/workflows/.github/workflows/main.yml/badge.svg) [![Docker Automated build](https://img.shields.io/docker/automated/sstc/action-rsync)](https://hub.docker.com/repository/docker/sstc/action-rsync)

- Small: Alpine based image with pre-installed rsync.
- Hooks: Basic pre and post scripts support.
- Pure 😊: No github special inputs, outputs. As a pure docker container, it can also be used on other ci!

## Quick start

> Github action

```yml
on: [push]
jobs:
  rsync:
    runs-on: ubuntu-latest
    steps:
      # Must checkout first, otherwise would get empty folder, see https://github.com/actions/checkout
      - uses: actions/checkout@v2
      # Modify `master` to valid version, from https://github.com/marketplace/actions/action-rsync
      - uses: up9cloud/action-rsync@master
        env:
          HOST: target.example.com
          KEY: ${{secrets.DEPLOY_SSH_KEY}}
          TARGET: /app/
```

> Docker

```bash
docker run -it --rm \
  -v $(pwd):/app \
  -w /app \
  -e HOST="target.example.com" \
  -e KEY="$(cat ~/.ssh/id_rsa)"
  -e TARGET="/app/" \
  sstc/action-rsync
```

## Env

|Key|Default value|Description|
|----|---|---|
|HOST||`Required only if MODE is push or pull`|
|USER|`root`|Remote server ssh user, it's useless when MODE is local|
|PORT|`22`|Remote server ssh port, it's useless when MODE is local|
|KEY||`Required only if MODE is push or pull` ssh private key|
|SOURCE|`./`|Source folder or file|
|TARGET||`Required` Target path for folder or file|
|MODE|`push`|Must be one of `push`, `pull`, `local`|
|||push: local (SOURCE) to remote (TARGET)|
|||pull: remote (SOURCE) to local (TARGET)|
|||push: local (SOURCE) to local (TARGET)|
|VERBOSE|`false`|Set it `true` if you want some tips|
|ARGS|`-avz --delete --exclude=/.git/ --exclude=/.github/`|rsync arguments|
|ARGS_MORE||More rsync arguments, it means the final rsync arguments will be: `$ARGS $ARGS_MORE`|
|||For example, if you set ARGS_MORE to `--no-o --no-g` and keep ARGS as default,|
|||the final full args will be: `-avz --delete --exclude=/.git/ --exclude=/.github/ --no-o --no-g`|
|SSH_ARGS|`-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet`|ssh arguments, if you set this, the PORT would be ignored.|
|RUN_SCRIPT_ON|`target`|Must be one of `source`, `target`, `local`, `remote`|
|||target: When MODE=`push`, run pre and post scripts on remote. Other modes runs on local.|
|||source: When MODE=`push`, run scripts on local. Other modes runs on remote.|
|||local: Always on local.|
|||remote: Always on remote.|
|PRE_SCRIPT||Run script before rsync, the server of RUN_SCRIPT_ON must support `mktemp` command|
|POST_SCRIPT||Run script after rsync, the server of RUN_SCRIPT_ON must support `mktemp` command|

### Example

```yml
on: [push]
jobs:
  rsync:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy to my ❤️
      uses: up9cloud/action-rsync@v1.1
      env:
        HOST: example.com
        KEY: ${{secrets.DEPLOY_SSH_KEY}}
        TARGET: /app/hello-service/

        VERBOSE: true
        USER: ubuntu
        # PORT: 2222 # no need to set this, because of $SSH_ARGS
        ARGS: -az --exclude=/.git/
        SSH_ARGS: '-p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
        SOURCE: ./public/

        PRE_SCRIPT: |
          echo start at:
          date -u
        POST_SCRIPT: "echo done at: && date -u"
```

See also: [.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/blob/master/.github/workflows/main.yml)
