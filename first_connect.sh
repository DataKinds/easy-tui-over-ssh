#!/bin/sh

# THIS FILE IS LLM GENERATED (GPT-5 THROUGH DUCK.AI). PROMPT:
# regenerate that first connection script. assume that all users are connecting to the SAME unix user and don't care about that user's actual name -- so just do everything relative to $HOME. have it do exactly this:
# 1. prompt the user to paste their public key and press enter
# 2. verify that the public key actually looks like a public key, and re-prompt the user if it doesn't
# 3. generate a UUID for that user
# 4. add that public key and UUID pair to authorized_keys
# 5. disconnect the user with instructions to reconnect via pubkey
# THIS SCRIPT HAS BEEN HAND-VERIFIED FOR SAFETY AND PROPER FUNCTIONALITY

set -eu

SSH_DIR="$HOME/.ssh"
AK="$SSH_DIR/authorized_keys"
TMP="$(mktemp /tmp/newkey.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "First-time setup: paste your public SSH key, then press Enter. Note that your account will be inexorably linked to whatever SSH key you paste here, so paste wisely."

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

chown --reference="$HOME" "$AK" || true

echo ""
echo "Key registered with USER_UUID=$UUID."
echo "This session will now be disconnected. Please reconnect using your SSH key -- rerunning the same SSH command should connect instantly and not give you a password prompt."
# short delay so user can read the message
sleep 2
exit 0
