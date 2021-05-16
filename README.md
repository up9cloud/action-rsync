# action-rsync ![.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/workflows/.github/workflows/main.yml/badge.svg) [![Docker Automated build](https://img.shields.io/docker/automated/sstc/action-rsync)](https://hub.docker.com/repository/docker/sstc/action-rsync)

- Small: Alpine based image with pre-installed rsync.
- Hooks: Basic pre and post scripts support.
- Pure 😊: No github special inputs, outputs. As a pure docker container, it also can be used on other CI!

## Quick start

> Github action (.github/workflows/*.yml)

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

> Drone CI (.drone.yml)

```yml
kind: pipeline
type: docker
name: default

steps:
  - name: deploy
    when:
      branch:
        - master
      event: [push]
    image: sstc/drone-rsync
    settings:
      key:
        from_secret: deploy_ssh_key
      host: target.example.com
      target: /app/
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

# Or aliases with prefix PLUGIN_, based on drone ci envs
docker run -it --rm \
  -v $(pwd):/app \
  -w /app \
  -e PLUGIN_HOST="target.example.com" \
  -e PLUGIN_KEY="$(cat ~/.ssh/id_rsa)"
  -e PLUGIN_TARGET="/app/" \
  sstc/action-rsync
```

## ENV

- `HOST`: Remote server ssh hostname or ip address
  - **Required only if** MODE is push or pull
- `USER`: Remote server ssh user
  - *Default value*: `root`
  - It's useless when MODE is local
- `PORT`: Remote server ssh port
  - *Default value*: `22`
  - It's useless when MODE is local
- `KEY`: The ssh private key
  - **Required only if** MODE is push or pull
- `SOURCE`: Source path for folder or file
  - *Default value*: `./`
- `TARGET`: Target path for folder or file
  - **Required**
- `MODE`:
  - *Default value*: `push`
  - Must be one of:
    - `push`: local (SOURCE) to remote (TARGET)
    - `pull`: remote (SOURCE) to local (TARGET)
    - `local`: local (SOURCE) to local (TARGET)
- `VERBOSE`:
  - *Default value*: `false`
  - Set it to `true` when you need some tips
- `ARGS`: Arguments for rsync
  - *Default value*: `-avz --delete --exclude=/.git/ --exclude=/.github/`
- `ARGS_MORE`: More rsync arguments
  - *Default value*:
  - It means the final rsync arguments will be: `$ARGS $ARGS_MORE`
  - For example, if you set ARGS_MORE to `--no-o --no-g` and keep ARGS as default
  - the final full args will be: `-avz --delete --exclude=/.git/ --exclude=/.github/ --no-o --no-g`
- `SSH_ARGS`: Arguments for ssh
  - *Default value*: `-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet`
  - `-p` value is dynamic, it would be changed when you set PORT
  - But what if you set SSH_ARGS, the PORT would be ignored
- `RUN_SCRIPT_ON`:
  - *Default value*: `target`
  - Must be one of:
    - `target`: When MODE is `push`, run pre and post scripts on remote. When MODE is others, run on local.
    - `source`: When MODE is `push`, run pre and post scripts on local. When MODE is others, run on remote.
    - `local`: Always run scripts on local.
    - `remote`: Always run scripts on remote.
- `PRE_SCRIPT`: The script runs before rsync
  - *Default value*:
  - The target system of RUN_SCRIPT_ON must support `mktemp` command
- `POST_SCRIPT`: The script runs after rsync
  - *Default value*:
  - The target system of RUN_SCRIPT_ON must support `mktemp` command

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
