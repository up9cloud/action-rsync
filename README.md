# action-rsync

- Alpine based image with installed rsync.
- Basic pre and post scripts support.
- Pure docker container, no github format things.

## Inputs, Outputs, ...

None and Pure 😊

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
      uses: up9cloud/action-rsync@v1.1
      env:
        # Required
        HOST: example.com
        KEY: ${{secrets.DEPLOY_SSH_KEY}} # ssh private key
        TARGET: /target/dir/ # target folder or file

        # Optional (with `default` values)
        VERBOSE: false # set it true if you want some tips
        USER: root # target server ssh user
        PORT: 22 # target server ssh port
        ARGS: -avz --delete --exclude=/.git/ --exclude=/.github/ # rsync arguments
        SSH_ARGS: '-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet' # ssh arguments, if you set this, the PORT would be ignored.
        SOURCE: ./ # source folder or file
        PRE_SCRIPT: "" # pre script runs on target server, target server must support `mktemp` command
        POST_SCRIPT: "" # post script runs on target server, target server must support `mktemp` command
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

        PRE_SCRIPT: "echo start at: \n date -u --rfc-3339=ns"
        POST_SCRIPT: "echo done at: && date -u --rfc-3339=ns"
```

> See 1 more example: https://github.com/up9cloud/action-rsync/blob/master/.github/workflows/main.yml
