# action-rsync ![.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/workflows/.github/workflows/main.yml/badge.svg) [![Docker Automated build](https://img.shields.io/docker/automated/sstc/action-rsync)](https://hub.docker.com/repository/docker/sstc/action-rsync)

- Small: Alpine based image with pre-installed rsync, see [sstc/rsync](https://hub.docker.com/r/sstc/rsync).
- Hooks: Basic pre and post scripts support.
- Pure 😊: No github specific inputs, outputs, it can be used on other platform!

## Quick start

> Github Action (`.github/workflows/*.yml`)

```yml
on: [push]
jobs:
  rsync:
    runs-on: ubuntu-latest
    steps:
      # Must checkout first, otherwise it would show empty folder, see https://github.com/actions/checkout
      - uses: actions/checkout@v4
      # Modify `master` to a valid version, see https://github.com/marketplace/actions/action-rsync
      - uses: up9cloud/action-rsync@master
        env:
          HOST: target.example.com
          KEY: ${{secrets.DEPLOY_SSH_KEY}}
          TARGET: /app/
```

> Drone CI (`.drone.yml`)

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
    image: sstc/action-rsync
    settings:
      # lowercase attributes, see https://readme.drone.io/plugins/overview/#plugin-inputs
      key:
        from_secret: deploy_ssh_key
      host: target.example.com
      target: /app/
```

> Docker Container

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

## ENVs

||Default Value|Description|
|---|---|---|
|**`HOST`**||Remote server ssh hostname or ip address<br>**Required if** **`MODE`** is `push` or `pull`|
|**`REMOTE_HOSTS`**||Multiple remote hosts<br>Could be comma separate items style, e.q. 1.2.3.4,8.8.4.4<br>or one line one item style, e.q. 8.8.8.8\n111.111.111.111<br>It will execute pre & post scripts on every host<br>**Required if** **`MODE`** is `push` or `pull`|
|**`USER`**|`root`|Remote server ssh user<br>It's useless when **`MODE`** is `local`|
|**`PORT`**|`22`|Remote server ssh port<br>It's useless when **`MODE`** is `local`|
|**`KEY`**||The ssh private key<br>**Required if** **`PASSWORD`** is not provided and **`MODE`** is `push` or `pull`|
|**`PASSWORD`**||The ssh password<br>**Required if** **`KEY`** is not provided and **`MODE`** is `push` or `pull`|
|**`SOURCE`**|`./`|Source path for folder or file|
|**`TARGET`**||Target path for folder or file<br>**Required**|
|**`MODE`**|`push`|Must be one of:<br>`push`: local (SOURCE) to remote (TARGET)<br>`pull`: remote (SOURCE) to local (TARGET)<br>`local`: local (SOURCE) to local (TARGET)|
|**`VERBOSE`**|`false`|Set it to `true` when you need some tips|
|**`ARGS`**|`-avz --delete --exclude=/.git/ --exclude=/.github/`|Arguments for rsync|
|**`ARGS_MORE`**||More rsync arguments. Append more args for rsync, it means the final rsync arguments will be: `$ARGS $ARGS_MORE`.<br><br>For example, if you set ARGS_MORE to be `--no-o --no-g` and keep ARGS as default, then the final args will be: `-avz --delete --exclude=/.git/ --exclude=/.github/ --no-o --no-g`|
|**`SSH_ARGS`**|`-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet`|Arguments for ssh. The value of `-p` is dynamic, depends on what value you set for `PORT`, but what if you set SSH_ARGS, the PORT would be ignored|
|**`RUN_SCRIPT_ON`**|`target`|Must be one of:<br>`target`: When **`MODE`** is `push`, run pre and post scripts on remote (because the target is on remote). When **`MODE`** is others, run on local.<br>`source`: When **`MODE`** is `push`, run pre and post scripts on local. When **`MODE`** is others, run on remote.<br>`local`: Always run scripts on local.<br>`remote`: Always run scripts on remote.|
|**`PRE_SCRIPT`**||The script runs before rsync.<br>The target system of RUN_SCRIPT_ON must support `mktemp` command|
|**`POST_SCRIPT`**||The script runs after rsync.<br>The target system of RUN_SCRIPT_ON must support `mktemp` command|

### Example

```yml
on: [push]
jobs:
  rsync:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to my ❤️
      uses: up9cloud/action-rsync@master
      env:
        HOST: example.com
        KEY: ${{secrets.DEPLOY_SSH_KEY}}
        # PASSWORD: ${{secrets.DEPLOY_SSH_PASSWORD}} # it's less secure, using KEY instead
        TARGET: /app/hello-service/

        VERBOSE: true
        USER: ubuntu
        # PORT: 2222 # no need to set this, because of $SSH_ARGS
        ARGS: -az --exclude=/.git/
        SSH_ARGS: '-p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
        SOURCE: ./public/

        PRE_SCRIPT: |
          echo "start at:"
          date -u
        POST_SCRIPT: |
          echo "done at:"
          date -u
```

See also: [.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/blob/master/.github/workflows/main.yml)

## TODO

- [ ] test ssh connection before executing
- [ ] benchmark, compare with other actions based on js
- [ ] lock the version of docker image
- [ ] let variable names more meaningful, e.q. HOST to REMOTE_HOST
