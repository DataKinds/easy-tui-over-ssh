# TUI-OVER-SSH PAVED ROAD

## WHAT IS IT?

A quick way to spin up and serve TUI based applications without modifying their code. Directly serve a TUI application to your users and track unique sessions using environment variables attached to a user's public key. And do it all without writing a single line of code.

## WHY IS IT?

Because [Wish](https://github.com/charmbracelet/wish) is epic, but writing your whole app in Golang isn't.

Or maybe you love Golang, but you've already got a TUI set up that doesn't use the [wonderful libraries by Charm](https://github.com/charmbracelet) so it's nontrivial to switch to Wish.

Or maybe you saw [SSH (Snake Session Handler / Secure Snake Home)](https://eieio.games/blog/secure-massively-multiplayer-snake/) and wanted to play around with something similar. But there's too much bespoke infrastructure and you want something off the shelf. 

This, my friends, is as off-the-shelf as it gets. Docker and OpenSSH, superpowered by [DataKinds](https://datakinds.github.io/).

## HOW IS IT USED?

Fork this repo, move your code into the `app/` directory, then modify `app/entry` to call your code!

If your app needs special setup to run under Docker, open the `Dockerfile` and scroll to the bottom. Find the comment for "USER BUILD SETUP", and put your thinking hat on! 

There's no good way around mandating a particular distro for the setup, and in this case I've chosen Alpine as it's a good noodle and works well in Docker.

Then, bring up the Docker Compose cluster how you've always done it. Modify the port allocations in `compose.yml`, modify whatever user-facing arguments you'd like -- they're all described in the compose file, then `docker compose up --build --remove-orphans`.

## WHEN IS IT?

Now!

Access the `$USER_UUID` environment variable from within your app and start serving customized user experiences right now.

## WHO IS IT? WHERE IS IT? WHENCE IS IT?

https://datakinds.github.io/ / MIT licensed