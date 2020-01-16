#!/bin/bash

# This is a wrapper to lictl
# Source: https://github.com/MinecraftServerControl/mscs

# Get executable name
PROG=$(basename $0)

# Setup the default user name.
USER_NAME="lithil"

# Setup the default installation location.
LOCATION="/opt/lithil"

# Run the lictl script.
if [ "$USER_NAME" = "$(whoami)" ]; then
  lictl "$@"
else
  sudo -u ${USER_NAME} -H lictl "$@"
fi