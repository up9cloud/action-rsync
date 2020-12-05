# action-rsync ![.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/workflows/.github/workflows/main.yml/badge.svg)

- Alpine based image with pre-installed rsync.
- Basic pre and post scripts support.
- Pure docker container, no github format things.

## Inputs, Outputs

None & Pure 😊

## Usage

```yml
on: [push]
jobs:
  rsync:
    runs-on: ubuntu-latest
    steps:
    # Must checkout first, otherwise would get empty folder, see https://github.com/actions/checkout
    - uses: actions/checkout@v2
    - name: Deploy to my ❤️
      # Modify `master` to valid version, get from https://github.com/marketplace/actions/action-rsync
      uses: up9cloud/action-rsync@master
      env:
        # Required (values are examples)
        TARGET: /target/path/ # Target path for folder or file

        # Required only if MODE is push or pull
        HOST: example.com
        KEY: ${{secrets.DEPLOY_SSH_KEY}} # ssh private key

        # Optional (those are `default` values)
        MODE: push # push: local (SOURCE) to remote (TARGET)
                   # pull: remote (SOURCE) to local (TARGET)
                   # local: local (SOURCE) to local (TARGET)
        VERBOSE: false # Set it true if you want some tips
        USER: root # Remote server ssh user, it's useless when MODE is local
        PORT: 22 # Remote server ssh port, it's useless when MODE is local
        ARGS: -avz --delete --exclude=/.git/ --exclude=/.github/ # rsync arguments
        ARGS_MORE: "" # More rsync arguments, it means the final rsync arguments will be:
                      # `$ARGS $ARGS_MORE`
                      # For example, if you set ARGS_MORE to `--no-o --no-g` and keep ARGS as default, then the final will be:
                      # `-avz --delete --exclude=/.git/ --exclude=/.github/ --no-o --no-g`
        SSH_ARGS: '-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet' # ssh arguments, if you set this, the PORT would be ignored.
        SOURCE: ./ # Source folder or file
        RUN_SCRIPT_ON: target # target: When MODE is push, run pre and post scripts on remote. Other modes runs on local.
                              # source: When MODE is push, run scripts on local. Other modes runs on remote.
                              # local: Whatever, runs on local.
                              # remote: Runs on remote.
        PRE_SCRIPT: "" # Run script before rsync, the server (RUN_SCRIPT_ON) must support `mktemp` command
        POST_SCRIPT: "" # Run script after rsync, the server (RUN_SCRIPT_ON) must support `mktemp` command
```

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
          date -u --rfc-3339=ns
        POST_SCRIPT: "echo done at: && date -u --rfc-3339=ns"
```

See also: [.github/workflows/main.yml](https://github.com/up9cloud/action-rsync/blob/master/.github/workflows/main.yml)
