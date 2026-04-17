FROM alpine:latest

# What's the name of the Unix user that will allow people to register on the server?
ARG NEW_USER_LOGIN=new-user

# What's the name of the Unix user that will allow people to access the TUI app?
ARG APP_USER_LOGIN=app

# Set up OpenSSH and its required folder structure for root access
RUN apk add --no-cache openssh shadow
RUN ssh-keygen -A
RUN \
    mkdir -p /root/.ssh/ && \
    touch /root/.ssh/authorized_keys && \
    touch /root/.ssh/known_hosts && \
    chmod -R 0600 /root/.ssh/ && \
    chown -R root:root /root/.ssh/ 

# Create the users:
#   * root
#   * the NEW_USER_LOGIN, allowing prospective users to SSH in
#   * the APP_USER_LOGIN, allowing registered users into the app
RUN usermod -p '' root
RUN useradd -m -p '' ${APP_USER_LOGIN}
RUN useradd -m -p '' ${NEW_USER_LOGIN}
USER ${APP_USER_LOGIN} 
# Link together the APP_USER's authorized_keys with the NEW_USER's authorized_keys
# This way first_connect.sh doesn't need special perms to write out new keys.
RUN mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys
USER ${NEW_USER_LOGIN}
ADD first_connect.sh ~/first_connect.sh
USER root

# Setup the SSH config, including making the user modifications from the variables above
ADD sshd_config /etc/ssh/sshd_config
RUN sed -i 's/NEW_USER_LOGIN/${NEW_USER_LOGIN}/g' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-De"]
# CMD ["sh","-c","strace -ff -o /tmp/sshd.trace /usr/sbin/sshd -D -ddd"]
# CMD ["sh"]