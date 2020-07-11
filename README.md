# action-rsync

- Alpine based image with installed rsync.
- Basic pre and post scripts support.
- Pure docker container, no github format things.

## Inputs, Outputs, ...

None and Pure 😊

## Usage

```yml
- name: Deploy to my ❤️
  id: deploy
  uses: up9cloud/action-rsync@v1.0.0
  env:
    # required
    HOST: example.com
    KEY: ${{secrets.DEPLOY_SSH_KEY}} # required, ssh private key
    TARGET: ${{secrets.DEPLOY_TARGET}} # required, the target folder

    # optional with `defaults`
    VERBOSE: false # set it true if you want some tips
    USER: root # target server user
    PORT: 22 # target server port
    ARGS: -avz --delete # rsync arguments
    SSH_ARGS: '-p 22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet' # ssh arguments, if you set this, the PORT would be ignored.
    SOURCE: ./ # the source folder

    # optional (default is none)
    PRE_SCRIPT: Target server time: `date -Iseconds` # pre script run on target server via ssh
    POST_SCRIPT: "echo done! && cd /app && tree -d" # post script run on target server via ssh
```

### Example

```yml
- name: Deploy to my ❤️
  id: deploy
  uses: up9cloud/action-rsync@v1.0.0
  env:
    HOST: example.com
    KEY: ${{secrets.DEPLOY_SSH_KEY}}
    TARGET: /app/hello-service/

    VERBOSE: true
    USER: core
    PORT: 2222
    ARGS: -avz
    SSH_ARGS: '-p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
    SOURCE: ./public/

    PRE_SCRIPT: Server time (Start): `date -u --rfc-3339=ns`
    POST_SCRIPT: Server time (Done): `date -u --rfc-3339=ns`
```
