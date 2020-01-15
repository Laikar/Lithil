#!/bin/sh

# This is a wrapper to lictl
# Source: https://github.com/MinecraftServerControl/mscs

# Get executable name
PROG=$(basename $0)

# Setup the default user name.
USER_NAME="lithil"

# Setup the default installation location.
LOCATION="/opt/lithil"

# Setup the arguments to the lictl script.
# shellcheck disable=SC2124
LITHIL_ARGS="-p $PROG -l $LOCATION -c $MSCS_DEFAULTS $@"

# Run the lictl script.
if [ "$USER_NAME" = "$(whoami)" ]; then
    echo A
  lictl "$LITHIL_ARGS"
else
    echo B
  sudo "PATH=$PATH" -u $USER_NAME -H lictl "$LITHIL_ARGS"
fi
echo C