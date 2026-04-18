# TUI-OVER-SSH PAVED ROAD

## WHAT IS IT?

A quick way to spin up and serve TUI based applications without modifying their code. Directly serve a TUI application to your users and track unique sessions using environment variables attached to a user's public key. And do it all without writing a single line of code.

## WHY IS IT?

Because [Wish](https://github.com/charmbracelet/wish) is epic, but writing your whole app in Golang isn't.

Or maybe you love Golang, but you've already got a TUI set up that doesn't use the [wonderful libraries by Charm](https://github.com/charmbracelet) so it's nontrivial to switch to Wish.

Or maybe you saw [SSH (Snake Session Handler / Secure Snake Home)](https://eieio.games/blog/secure-massively-multiplayer-snake/) and wanted to play around with something similar. But there's too much bespoke infrastructure and you want something off the shelf. 

This, my friends, is as off-the-shelf as it gets. Docker and OpenSSH, superpowered by [DataKinds](https://datakinds.github.io/).

## HOW IS IT USED?

### ... *for developers*

Fork this repo, move your code into the `app/` directory, then modify `app/entry` to call your code!

If your app needs special setup to run under Docker, open the `Dockerfile` and scroll to the bottom. Find the comment for "USER BUILD SETUP", and put your thinking hat on! 

There's no good way around mandating a particular distro for the setup, and in this case I've chosen Alpine as it's a good noodle and works well in Docker.

Then, bring up the Docker Compose cluster how you've always done it. Modify the port allocations in `compose.yml`, modify whatever user-facing arguments you'd like -- they're all described in the compose file, then `docker compose up --build --remove-orphans`.

### ... *for users*

Using an app deployed through this paved road is easy. It's just a normal SSH connection, so it'll work with any of the standard tools you're used to working with. Terminal multiplexers are no issue here. Getting set up is an easy process:

#### Generate your SSH key, if you haven't already!

Follow the prompts on screen -- it'll ask you where to put the key and if you want a password. Customize as desired but the defaults should be fine.

```
$ ssh-keygen -t ed25519
```

#### Copy your SSH key to the clipboard

```
$ cat ~/.ssh/id_ed25519.pub
```

#### Then finally, connect to the new user registration SSH box!

The command below uses the default values (`new-user` and `1337`, namely) for the paved road. Whoever's deployed the application has probably customized these values, so make sure to check with them! This command will then give you all the instructions you need to start using the app. Have fun!

```
$ ssh -p 1337 new-user@my.epic.app.gov
```

## WHEN IS IT?

Now!

Access the `$USER_UUID` environment variable from within your app and start serving customized user experiences right now.

### [BRIEF ROADMAP](https://github.com/DataKinds/easy-tui-over-ssh/blob/main/ROADMAP.md)

There are a few open areas to improve the paved road. Interested in helping? [Open a pull request now](https://github.com/DataKinds/easy-tui-over-ssh/pulls)!

## WHENCE IS IT? (FAQ)

### How does it authenticate users?

A unique UUID is attached to your public key pair on the server when you connect to the new user box for the first time. Then going forward, a user's public/private keypair is how they authenticate.

### Can I make multiple accounts?

Yes! Your account information is attached to your public/private keypair, so if you set up a new keypair and register with that you'll be able to have multiple accounts. When you connect to the application, you can use the `-i` flag on `ssh` to pass a specific private key.

### How many Unix users are set up under SSHD?

We configure 3 user accounts when we create the SSH tunnel container:

* `root`, which will be available for application administration -- however right now you're not able to connect to it (see roadmap above).
* `new-user`, configurable as `NEW_USER_LOGIN`/`NEW_USER_PASSWORD` -- this Unix box allows users to register their public keys.
* `app`, configurable as `APP_USER_LOGIN` -- this Unix box will actually serve your application as a custom shell.

## WHO IS IT? WHERE IS IT? 

https://datakinds.github.io/ / MIT licensed