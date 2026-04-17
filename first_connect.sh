#!/bin/sh

# TODO: most of this script could LITERALLY be replaced by `ExposeAuthInfo` setting in sshd_config

set -eu

SSH_DIR="$HOME/.ssh"
AK="$SSH_DIR/authorized_keys"
TMP="$(mktemp /tmp/newkey.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

DEPLOYED_HOST=$(echo "$DEPLOYED_HOSTPORT" | cut -d ':' -f 1)
DEPLOYED_PORT=$(echo "$DEPLOYED_HOSTPORT" | cut -d ':' -f 2)

connect_message() {
    echo "HELLO! Welcome to the first-time setup for $HOSTNAME."
    echo "This setup process is supported by https://github.com/DataKinds/easy-tui-over-ssh."
    echo "Please paste your public SSH key, then press Enter."
    echo "Note that whatever key you paste here will be linked to your account forever and always. So paste carefully!"
}

# expects the user UUID to passed as the first param
disconnect_message() {
    echo ""
    echo "... thinking, cajoling, processing, unvexing, ..."
    sleep 1
    echo ""
    echo "Key registered for user UUID $1. No need to memorize this ID -- we're just confirming that we've registered your account!"
    echo "This session will now be disconnected. Please reconnect to the real application by running the following SSH command:"
    echo ""
    echo "  ssh -p $DEPLOYED_PORT $DEPLOYED_APP_USER@$DEPLOYED_HOST"
    echo ""
    echo "Thank you!"
    # short delay so user can read the message
    sleep 2
    exit 0
}


# mkdir -p "$SSH_DIR"
# chmod 700 "$SSH_DIR"

connect_message

# Basic public-key regex (supports rsa, ed25519, dss, ecdsa)
is_pubkey() {
  # field1 = key type, field2 = base64 blob (no spaces), optional comment allowed afterwards
  echo "$1" | grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2-nistp(256|384|521)) [A-Za-z0-9+/=]+( .*)?$'
}


while :; do
  # read one full line (allow users to paste whole line)
  if ! IFS= read -r line; then
    echo "No input; aborting."
    exit 1
  fi
  # trim leading/trailing whitespace
  key="$(printf '%s' "$line" | awk '{$1=$1;print}')"
  if is_pubkey "$key"; then
    printf '%s\n' "$key" > "$TMP"
    break
  else
    echo "Invalid key format. Please paste a valid SSH public key (e.g. starts with 'ssh-ed25519' or 'ssh-rsa') and press Enter:"
  fi
done

# generate UUID (uuidgen not available in Alpine by default, but we fallback to /dev/urandom+hexdump)
if command -v uuidgen >/dev/null 2>&1; then
  UUID="$(uuidgen)"
else
  UUID="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n' | sed 's/\(..\)/\1/g' | awk '{printf("%s-%s-%s-%s-%s\n", substr($0,1,8), substr($0,9,4), substr($0,13,4), substr($0,17,4), substr($0,21));}')"
fi

# append to authorized_keys with environment tag
# ensure the environment option is allowed by sshd (AcceptEnv not needed; environment= in authorized_keys is server-sided)
# Format: environment="USER_UUID=..." <pubkey>
printf 'environment="USER_UUID=%s" %s\n' "$UUID" "$(cat "$TMP")" >> "$AK"

disconnect_message "$UUID"