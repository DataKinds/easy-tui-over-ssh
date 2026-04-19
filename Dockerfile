FROM alpine:latest

# What's the name of the Unix user that will allow people to register on the server?
ARG NEW_USER_LOGIN=new-user
ARG NEW_USER_PASSWORD=login
# What's the name of the Unix user that will allow people to access the TUI app?
ARG APP_USER_LOGIN=app
# What's the forward-deployed hostname/port pair for the app? Used for error messages and instructions
ARG APP_DEPLOYED_HOSTPORT=localhost:1337
# What public key should be configured to allow root access?
ARG ROOT_TRUSTED_KEY


# Set up OpenSSH and its required folder structure for root access
RUN apk add --no-cache openssh shadow docker
RUN ssh-keygen -A
RUN \
    mkdir -p /root/.ssh/ && \
    echo "${ROOT_TRUSTED_KEY}" > /root/.ssh/authorized_keys && \
    touch /root/.ssh/known_hosts && \
    chmod -R 0600 /root/.ssh/ && \
    chown -R root:root /root/.ssh/ 

# Create the users:
#   * root
#   * the NEW_USER_LOGIN, allowing prospective users to SSH in
#   * the APP_USER_LOGIN, allowing registered users into the app
RUN usermod -p '' root
RUN useradd -m -p '' ${APP_USER_LOGIN}
RUN useradd -m -p '' ${NEW_USER_LOGIN} && \
    usermod -a -G ${APP_USER_LOGIN} ${NEW_USER_LOGIN} && \
    echo "${NEW_USER_LOGIN}:${NEW_USER_PASSWORD}" | chpasswd
# Set up the APP_USER's authorized_keys to be linked to the NEW_USER's authorized_keys
# (remember: chmod 0770 means "read+write+execute for only me and my group")
USER ${APP_USER_LOGIN} 
RUN mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R 0770 ~/.ssh/authorized_keys
# Set up the NEW_USER's initial login script
USER ${NEW_USER_LOGIN}
ADD --chown=${NEW_USER_LOGIN}:${NEW_USER_LOGIN} first_connect.sh /home/${NEW_USER_LOGIN}/first_connect.sh
RUN chmod 0700 ~/first_connect.sh
RUN mkdir -p ~/.ssh
# Link together the NEW_USER's authorized_keys with the APP_USER's authorized_keys
# This way first_connect.sh doesn't need special perms to write out new keys.
USER root
RUN ln -s /home/${APP_USER_LOGIN}/.ssh/authorized_keys /home/${NEW_USER_LOGIN}/.ssh/authorized_keys && \
    chown -h ${NEW_USER_LOGIN}:${NEW_USER_LOGIN} /home/${NEW_USER_LOGIN}/.ssh/authorized_keys

# Setup the SSH config, including making the templated user modifications from the variables above
ADD sshd_config /etc/ssh/sshd_config
RUN sed -i "s/NEW_USER_LOGIN/${NEW_USER_LOGIN}/g" /etc/ssh/sshd_config &&\
    sed -i "s/APP_USER_LOGIN/${APP_USER_LOGIN}/g" /etc/ssh/sshd_config &&\
    sed -i "s/APP_DEPLOYED_HOSTPORT/${APP_DEPLOYED_HOSTPORT}/g" /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-De"]


###############################################################################################################
# USER BUILD SETUP!                                                                                           #
# Here's where you'll set up your application to run in Alpine.                                               #
# Remember that I'm just going to be calling `app/entry` with no args as the entrypoint for the whole app.    #
# The actual configuration for that entrypoint exists in sshd_config, in the Match User APP_USER_LOGIN block. #
# And by default, I'm gonna put your app at `/app`, as is tradition.                                          #
###############################################################################################################
# Copy in the app folder, give it to the SSH user that's running the app
ADD --chown=${APP_USER_LOGIN}:${APP_USER_LOGIN} app/ /app
RUN chmod -R +x /app
# Do whatever else you need to in order to build or set up your app here! You want volumes? Watchdogs? You got it!