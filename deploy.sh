#!/usr/bin/env bash

set -euo pipefail

action='{{ action }}'
installable='{{ installable }}'
profile='{{ profile }}'
nixConfig='{{ nixConfig }}'


NIX_CONFIG="$nixConfig" nix build \
  --extra-experimental-features 'nix-command flakes' \
  --refresh \
  --profile "$profile" \
  "$installable"

if [ "$(readlink -f /run/current-system)" == "$(readlink -f "$profile")" ]; then
  echo "Already booted into the desired configuration"
  exit 0
fi

do_reboot=0
if [ "$action" == "reboot" ]; then
  action="boot"
  do_reboot=1
fi

sudo "$profile/bin/switch-to-configuration" "$action"

if [ "$do_reboot" == 1 ]; then
  exit 194
fi