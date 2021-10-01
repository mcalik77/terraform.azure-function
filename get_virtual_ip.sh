#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract "hostname" argument from the input into
# HOSTNAME shell variables.
#
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "HOSTNAME=\(.hostname)"')"

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
VIRTUAL_IP=`dig +short "$HOSTNAME" | grep '^[.0-9]*$'`
jq -n --arg virtual_ip "$VIRTUAL_IP" '{"virtual_ip":$virtual_ip}'