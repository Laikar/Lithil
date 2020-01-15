#!/bin/sh

# ---------------------------------------------------------------------------
# Copyright (c) 2011-2016, Jason M. Wood <sandain@hotmail.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Minecraft Server Control Script
#
# A powerful command-line control script for Linux-powered Minecraft servers.
# ---------------------------------------------------------------------------

# Get executable name
# ---------------------------------------------------------------------------
PROG=$(basename $0)

# Required Software
# ---------------------------------------------------------------------------
# Detect its presence and location for later.
JAVA=$(which java)
PERL=$(which perl)
PYTHON=$(which python)
WGET=$(which wget)
RDIFF_BACKUP=$(which rdiff-backup)
RSYNC=$(which rsync)
SOCAT=$(which socat)

# Script Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage:  $PROG [<options>] <action>

Actions:

  start <world1> <world2> <...>
    Start the Minecraft world server(s).  Start all world servers by default.

  stop <world1> <world2> <...>
    Stop the Minecraft world server(s).  Stop all world servers by default.

  force-stop <world1> <world2> <...>
    Forcibly stop the Minecraft world server(s).  Forcibly stop all world
    servers by default.

  restart <world1> <world2> <...>
    Restart the Minecraft world server(s).  Restart all world servers by default.

  force-restart <world1> <world2> <...>
    Forcibly restart the Minecraft world server(s).  Forcibly restart all world
    servers by default.

  create <world> <port> [<ip>]
    Create a Minecraft world server.  The world name and port must be
    provided, the IP address is usually blank.  Without arguments, create a
    a default world at the default port.

  import <directory> <world> <port> [<ip>]
    Import an existing world server.  The world name and port must be
    provided, the IP address is usually blank.

  rename <original world> <new world>
    Rename an existing world server.

  delete <world>
    Delete a Minecraft world server.

  disable <world1> <world2> <...>
    Temporarily disables world server(s). Disables all world servers by default.

  enable <world1> <world2> <...>
    Enable disabled world server(s). Enables all world servers by default.

  ls <option>
    Display a list of worlds.
    Options:
      enabled   Display a list of enabled worlds, default.
      disabled  Display a list of disabled worlds.
      running   Display a list of running worlds.
      stopped   Display a list of stopped worlds.
    If no option, all available worlds are listed.

  list <option>
    Same as 'ls' but more detailed.

  status <world1> <world2> <...>
    Display the status of Minecraft world server(s).  Display the status of
    all world servers by default.

  sync <world1> <world2> <...>
    Synchronize the data stored in the mirror images of the Minecraft world
    server(s).  Synchronizes all of the world servers by default.  This option
    is only available when the mirror image option is enabled.

  broadcast <command>
    Broadcast a command to all running Minecraft world servers.

  send <world> <command>
    Send a command to a Minecraft world server.

  console <world>
    Connect to the Minecraft world server's console.  Hit <Ctrl-D> to detach.

  watch <world>
    Watch the log file for the Minecraft world server.

  logrotate <world1> <world2> <...>
    Rotate the log file for the Minecraft world(s).  Rotate the log file for
    all worlds by default.

  backup <world1> <world2> <...>
    Backup the Minecraft world(s).  Backup all worlds by default.

  list-backups <world>
    List the datetime of the backups for the world.

  restore-backup <world> <datetime>
    Restore a backup for a world that was taken at the datetime.

  map <world1> <world2> <...>
    Run the Minecraft Overviewer mapping software on the Minecraft world(s).
    Map all worlds by default.

  update <world1> <world2> <...>
    Update the server software for the Minecraft world server(s).  Update
    server software for all worlds by default.

  force-update <world1> <world2> <...>
    Refresh version information prior to running update for the world
    server(s), regardless of how recently the version information was updated.
    Refreshes version information and updates all world servers by default.

  query <world1> <world2> <...>
    Run a detailed Query on the Minecraft world server(s). Run a detailed
    query on all world servers by default.

Options:

  -c <config_file>
    Read configuration from <config_files> instead of default locations.

  -l <location>
    Uses <location> as the base path for data.  Overrides configuration file
    options.
EOF
}

mscs_defaults() {
  cat <<EOF
; MSCS defaults file for adjusting global server properties.

; Default values in the script can be overridden by adding certain properties
; to one of the mscs.defaults files. The mscs.defaults files can be found
; found in one of three places depending on how the script is being used. When
; using the mscs script, the mscs.defaults file can be found at
; /opt/mscs/mscs.defaults. When using the msctl script in multi-user mode,
; the mscs.defaults file can be found at either \$HOME/mscs.defaults or
; \$HOME/.config/mscs/mscs.defaults.

; Uncomment key=value pairs (remove the #) to customize the value for your
; configuration. The values shown are the default values used in the script.

; Location of the mscs files.
# mscs-location=/opt/mscs

; Location of world files.
# mscs-worlds-location=/opt/mscs/worlds

; URL to download the version_manifest.json file.
# mscs-versions-url=https://launchermeta.mojang.com/mc/game/version_manifest.json

; Location of the version_manifest.json file.
# mscs-versions-json=/opt/mscs/version_manifest.json

; Length in minutes to keep the version_manifest.json file before updating.
# mscs-versions-duration=30

; Length in minutes to keep lock files before removing.
# mscs-lockfile-duration=1440

; Properties to return for detailed listings.
# mscs-detailed-listing=motd server-ip server-port max-players level-type online-mode

; Default world name.
# mscs-default-world=world

; Default Port.
# mscs-default-port=25565

; Default IP address. Leave this blank unless you want to bind all world
; servers to a single network interface by default.
# mscs-default-ip=

; Default version type (release or snapshot).
# mscs-default-version-type=release

; Default version of the client software. You can use the \$CURRENT_VERSION
; variable to access the latest version based on the version type selected.
# mscs-default-client-version=\$CURRENT_VERSION

; Default .jar file for the client software. The \$CLIENT_VERSION variable
; allows access to the client version selected.
# mscs-default-client-jar=\$CLIENT_VERSION.jar

; Default download URL for the client software. The \$CLIENT_VERSION variable
; allows access to the client version selected.
# mscs-default-client-url=

; Default location of the client .jar file. The \$CLIENT_VERSION variable
; allows access to the client version selected.
# mscs-default-client-location=/opt/mscs/.minecraft/versions/\$CLIENT_VERSION

; Default version of the server software. You can use the \$CURRENT_VERSION
; variable to access the latest version based on the version type selected.
# mscs-default-server-version=\$CURRENT_VERSION

; Default arguments for the JVM.
# mscs-default-jvm-args=

; Default .jar file for the server software. The \$SERVER_VERSION variable
; allows access to the server version selected.
# mscs-default-server-jar=minecraft_server.\$SERVER_VERSION.jar

; Default download URL for the server software. The \$SERVER_VERSION variable
; allows access to the server version selected.
# mscs-default-server-url=

; Default arguments for a world server.
# mscs-default-server-args=nogui

; Default initial amount of memory for a world server.
# mscs-default-initial-memory=128M

; Default maximum amount of memory for a world server.
# mscs-default-maximum-memory=2048M

; Default location of the server .jar file.
# mscs-default-server-location=/opt/mscs/server

; Default command to run for a world server. You can use the \$JAVA variable to
; access the results of \$(which java). The \$INITIAL_MEMORY and \$MAXIMUM_MEMORY
; variables provide access to the amounts of memory selected. The
; \$SERVER_LOCATION and \$SERVER_JAR variables provide access to the location
; and file name of the server software selected. The \$SERVER_ARGS variable
; provides access to the arguments for the world server selected.
# mscs-default-server-command=\$JAVA -Xms\$INITIAL_MEMORY -Xmx\$MAXIMUM_MEMORY -jar \$SERVER_LOCATION/\$SERVER_JAR \$SERVER_ARGS

; Location to store backup files.
# mscs-backup-location=/opt/mscs/backups

; Location of the backup log file.
# mscs-backup-log=/opt/mscs/backups/backup.log

; Length in days that backups survive. A value less than 1 disables backup deletion.
# mscs-backup-duration=15

; Length in days that logs survive. A value less than 1 disables log deletion.
# mscs-log-duration=15

; Enable the mirror option by default for worlds (default disabled). Change
; to a 1 to enable.
# mscs-enable-mirror=0

; Default path for the mirror files.
# mscs-mirror-path=/dev/shm/mscs

; Location of Overviewer.
# mscs-overviewer-bin=/usr/bin/overviewer.py

; URL for Overviewer.
# mscs-overviewer-url=http://overviewer.org

; Location of Overviewer generated map files.
# mscs-maps-location=/opt/mscs/maps

; URL for accessing Overviewer generated maps.
# mscs-maps-url=http://minecraft.server.com/maps
EOF
}

# ---------------------------------------------------------------------------
# Internal Methods
# ---------------------------------------------------------------------------
#
# NOTE: Nothing below this point should need to be edited directly.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Get the PID of the Java process for the world server.
#
# @param 1 The world server of interest.
# @return The Java PID.
# ---------------------------------------------------------------------------
getJavaPID() {
  local PID MCUSER
  MCUSER=$(whoami)
  PID=$(
    ps -a -U $MCUSER -o pid,comm,args -ww |
      $PERL -ne 'if ($_ =~ /^\s*(\d+)\s+java.+mscs-world='$1'$/) { print $1; }'
  )
  printf "%d\n" $PID
}

# ---------------------------------------------------------------------------
# Get the amount of memory used by the Java process for the world server.
#
# @param 1 The world server of interest.
# @return The amount of memory used.
# ---------------------------------------------------------------------------
getJavaMemory() {
  local PID
  PID=$(getJavaPID "$1")
  ps --no-headers -p $PID -o rss
}

# ---------------------------------------------------------------------------
# Check to see if the world server is running.
#
# @param 1 The world server of interest.
# @return A 0 if the server is thought to be running, a 1 otherwise.
# ---------------------------------------------------------------------------
serverRunning() {
  # Try to determine if the world is running.
  if [ $(getJavaPID "$1") -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Send a command to the world server.
#
# @param 1 The world server of interest.
# @param 2 The command to send.
# ---------------------------------------------------------------------------
sendCommand() {
  echo "$2" | $PERL -e '
    while (<>) { $_ =~ s/[\r\n]+//g; $cmd .= $_; } print "$cmd\r";
  ' >>$WORLDS_LOCATION/$1/console.in
}

# ---------------------------------------------------------------------------
# Check whether the item is in the list.
#
# @param 1 The item being searched for.
# @param 2 The list being searched.
# @return A 0 if the list contains the item, a 1 otherwise.
# ---------------------------------------------------------------------------
listContains() {
  local MATCH ITEM
  MATCH=1
  for ITEM in $2; do
    if [ "$ITEM" = "$1" ]; then
      MATCH=0
    fi
  done
  return $MATCH
}

# ---------------------------------------------------------------------------
# Compare two datetime strings.
#
# @param 1 The first datetime string.
# @param 2 The second datetime string.
# @return The result of the comparison: -1, 0, 1.
# ---------------------------------------------------------------------------
compareTime() {
  local T1 T2
  T1=$(date --date="$1" +%s)
  T2=$(date --date="$2" +%s)
  printf $(($T1 < $T2 ? -1 : $T1 > $T2 ? 1 : 0))
}

# ---------------------------------------------------------------------------
# Compare two Minecraft version numbers.
#
# @param 1 The first Minecraft version number.
# @param 2 The second Minecraft version number.
# @return The result of the comparison: -1, 0, 1.
# ---------------------------------------------------------------------------
compareMinecraftVersions() {
  local T1 T2
  T1=$(getMinecraftVersionReleaseTime "$1")
  T2=$(getMinecraftVersionReleaseTime "$2")
  compareTime "$T1" "$T2"
}

# ---------------------------------------------------------------------------
# Create a world.
#
# @param 1 The world server to create.
# @param 2 The port of the world server.
# @param 3 The IP address of the world server.
# ---------------------------------------------------------------------------
createWorld() {
  # Create a basic server.properties file.  Values not supplied here
  # will use default values when the world server is first started.
  mkdir -p "$WORLDS_LOCATION/$1"
  setServerPropertiesValue "$1" "level-name" "$1"
  setServerPropertiesValue "$1" "server-port" "$2"
  setServerPropertiesValue "$1" "server-ip" "$3"
  setServerPropertiesValue "$1" "enable-query" "true"
  setServerPropertiesValue "$1" "query.port" "$2"
  setMSCSValue "$1" "mscs-enabled" "true"
}

# ---------------------------------------------------------------------------
# Delete a world.
#
# @param 1 The world server to delete.
# ---------------------------------------------------------------------------
deleteWorld() {
  # Delete the world directory.
  rm -Rf "$WORLDS_LOCATION/$1"
}

# ---------------------------------------------------------------------------
# Disable a world.
#
# @param 1 The world server to disable.
# ---------------------------------------------------------------------------
disableWorld() {
  # Disable the world.
  setMSCSValue "$1" "mscs-enabled" "false"
}

# ---------------------------------------------------------------------------
# Enable a world.
#
# @param 1 The world server to enable.
# ---------------------------------------------------------------------------
enableWorld() {
  # Enable the world.
  setMSCSValue "$1" "mscs-enabled" "true"
}

# ---------------------------------------------------------------------------
# Import a world.
#
# @param 1 The location of the world to import.
# @param 2 The name of the new imported world.
# @param 3 The port of the new imported world.
# @param 4 The IP address of the new imported world.
# ---------------------------------------------------------------------------
importWorld() {
  local NAME
  mkdir -p "$WORLDS_LOCATION/$2"
  cp -R $1/* $WORLDS_LOCATION/$2
  chown $(id -un):$(id -gn) -R $WORLDS_LOCATION/$2
  NAME=$(getServerPropertiesValue $2 'level-name')
  if [ -d $WORLDS_LOCATION/$2/$NAME ]; then
    mv $WORLDS_LOCATION/$2/$NAME $WORLDS_LOCATION/$2/$2
  fi
  createWorld "$2" "$3" "$4"
}

# ---------------------------------------------------------------------------
# Grab the list of enabled worlds.
#
# @return The list of enabled worlds.
# ---------------------------------------------------------------------------
getEnabledWorlds() {
  local WORLD WORLDS
  mkdir -p "$WORLDS_LOCATION"
  WORLDS=""
  for WORLD in $(ls $WORLDS_LOCATION); do
    if [ -d $WORLDS_LOCATION/$WORLD ]; then
      if [ "$(getMSCSValue $WORLD 'mscs-enabled' 'true')" = "true" ]; then
        WORLDS="$WORLDS $WORLD"
      fi
    fi
  done
  printf "$WORLDS"
}

# ---------------------------------------------------------------------------
# Grab the list of disabled worlds.
#
# @return The list of disabled worlds.
# ---------------------------------------------------------------------------
getDisabledWorlds() {
  local WORLD WORLDS
  WORLDS=""
  for WORLD in $(ls $WORLDS_LOCATION); do
    if [ -d $WORLDS_LOCATION/$WORLD ]; then
      if [ "$(getMSCSValue $WORLD 'mscs-enabled' 'true')" != "true" ]; then
        WORLDS="$WORLDS $WORLD"
      fi
    fi
  done
  printf "$WORLDS"
}

# ---------------------------------------------------------------------------
# Grab the list of all available worlds.
#
# @return The list of all available worlds.
# ---------------------------------------------------------------------------
getAvailableWorlds() {
  printf "$(getEnabledWorlds) $(getDisabledWorlds)"
}

# ---------------------------------------------------------------------------
# Check to see if the world is enabled.
#
# @param 1 The world of interest.
# @return A 0 if the world is enabled, a 1 otherwise.
# ---------------------------------------------------------------------------
isWorldEnabled() {
  local WORLDS
  WORLDS=$(getEnabledWorlds)
  if [ -n "$1" ] && listContains "$1" "$WORLDS"; then
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Check to see if the world is disabled.
#
# @param 1 The world of interest.
# @return A 0 if the world is disabled, a 1 otherwise.
# ---------------------------------------------------------------------------
isWorldDisabled() {
  local WORLDS
  WORLDS=$(getDisabledWorlds)
  if [ -n "$1" ] && listContains "$1" "$WORLDS"; then
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Check to see if the world is available (exists).
#
# @param 1 The world of interest.
# @return A 0 if the world is available, a 1 otherwise.
# ---------------------------------------------------------------------------
isWorldAvailable() {
  local WORLDS
  WORLDS=$(getAvailableWorlds)
  if [ -n "$1" ] && listContains "$1" "$WORLDS"; then
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Get the value of a key from the provided file.
#
# @param 1 The file containing the key/value combo.
# @param 2 The key to get.
# @param 3 The default value.
# ---------------------------------------------------------------------------
getValue() {
  local KEY VALUE
  # Make sure the file exists.
  if [ -e "$1" ]; then
    # Find the key/value combo.
    KEY=$($PERL -ne '
      # Remove single and double quotes plus CR and LF.
      $_ =~ s/[\x22\x27\r\n]//g;
      # Remove comments that begin with # or ;.
      $_ =~ s/^\s*[\x23\x3B].*//;
      # Extract the key.
      if ($_ =~ /^\s*('$2')\s*=\s*.*$/i) { print lc $1; }
    ' $1)
    VALUE=$($PERL -ne '
      # Remove single and double quotes plus CR and LF.
      $_ =~ s/[\x22\x27\r\n]//g;
      # Remove comments that begin with # or ;.
      $_ =~ s/^\s*[\x23\x3B].*//;
      # Extract the value.
      if ($_ =~ /^\s*'$2'\s*=\s*(.*)$/i) { print $1; }
    ' $1)
  fi
  # Return the value if found, the default value if not.
  if [ -n "$KEY" ] && [ -n "$VALUE" ]; then
    # $VALUE may contains flag-like strings not intended for printf
    printf -- "$VALUE"
  else
    printf -- "$3"
  fi
}

# ---------------------------------------------------------------------------
# Modify the value of a key/value combo in the provided file.
#
# @param 1 The file containing the key/value combo.
# @param 2 The key to modify.
# @param 3 The value to assign to the key.
# ---------------------------------------------------------------------------
setValue() {
  local KEY_VALUE
  # Make sure that the file exists.
  touch "$1"
  # Replace the key/value combo if it already exists, otherwise just
  # append it to the end of the file.
  KEY_VALUE=$($PERL -ne '
    $_ =~ s/[\r]//;
    if ($_ =~ /^('$2'=.*)$/) { print "$1"; }
  ' $1)
  if [ -n "$KEY_VALUE" ]; then
    $PERL -i -ne '
      $_ =~ s/[\r]//;
      if ($_ =~ /^'$2'=.*$/) { print "'$2'='$3'\n"; } else { print; }
    ' $1
  else
    printf "$2=$3\n" >>"$1"
  fi
}

# ---------------------------------------------------------------------------
# Get the value of a key in the mscs.defaults file.
#
# @param 1 The key to get.
# @param 2 The default value.
# ---------------------------------------------------------------------------
getDefaultsValue() {
  getValue "$MSCS_DEFAULTS" "$1" "$2"
}

# ---------------------------------------------------------------------------
# Get the value of the EULA boolean.
#
# @param 1 The world server of interest.
# ---------------------------------------------------------------------------
getEULAValue() {
  local EULA_FILE
  EULA_FILE=$WORLDS_LOCATION/$1/eula.txt
  getValue "$EULA_FILE" "eula" "true" | $PERL -ne 'print lc'
}

# ---------------------------------------------------------------------------
# Get the value of a key in a mscs.properties file.
#
# @param 1 The world server of interest.
# @param 2 The key to get.
# @param 3 The default value.
# ---------------------------------------------------------------------------
getMSCSValue() {
  local PROPERTY_FILE
  PROPERTY_FILE=$WORLDS_LOCATION/$1/mscs.properties
  getValue "$PROPERTY_FILE" "$2" "$3"
}

# ---------------------------------------------------------------------------
# Modify the value of a key/value combo in a mscs.properties file.
#
# @param 1 The world server of interest.
# @param 2 The key to modify.
# @param 3 The value to assign to the key.
# ---------------------------------------------------------------------------
setMSCSValue() {
  local PROPERTY_FILE
  PROPERTY_FILE=$WORLDS_LOCATION/$1/mscs.properties
  setValue "$PROPERTY_FILE" "$2" "$3"
}

# ---------------------------------------------------------------------------
# Get the value of a key in a server.properties file.
#
# @param 1 The world server of interest.
# @param 2 The key to get.
# @param 3 The default value.
# ---------------------------------------------------------------------------
getServerPropertiesValue() {
  local PROPERTY_FILE
  PROPERTY_FILE="$WORLDS_LOCATION/$1/server.properties"
  getValue "$PROPERTY_FILE" "$2" "$3"
}

# ---------------------------------------------------------------------------
# Modify the value of a key/value combo in a server.properties file.
#
# @param 1 The world server of interest.
# @param 2 The key to modify.
# @param 3 The value to assign to the key.
# ---------------------------------------------------------------------------
setServerPropertiesValue() {
  local PROPERTY_FILE
  PROPERTY_FILE=$WORLDS_LOCATION/$1/server.properties
  setValue "$PROPERTY_FILE" "$2" "$3"
}

# ---------------------------------------------------------------------------
# Update the version_manifest.json file.
# ---------------------------------------------------------------------------
updateVersionsJSON() {
  if [ -s $VERSIONS_JSON ]; then
    # Make a backup copy of the version_manifest.json file.
    cp -p "$VERSIONS_JSON" "$VERSIONS_JSON.bak"
    # Delete the version_manifest.json file if it is old.
    find "$VERSIONS_JSON" -mmin +"$VERSIONS_DURATION" -delete
    if [ -s $VERSIONS_JSON ]; then
      printf "The cached copy of the version manifest is up to date.\n"
      printf "Use the force-update option to ensure a new copy is downloaded.\n"
    else
      printf "The version manifest cache was out of date, it has been removed.\n"
    fi
  fi
  # Download the version_manifest.json file if it does not exist.
  if [ ! -s $VERSIONS_JSON ]; then
    printf "Downloading current Minecraft version manifest.\n"
    $WGET --no-use-server-timestamps -qO "$VERSIONS_JSON" "$MINECRAFT_VERSIONS_URL"
    if [ $? -ne 0 ]; then
      if [ -s $VERSIONS_JSON.bak ]; then
        printf "Error downloading the version manifest, using a backup.\n"
        cp -p "$VERSIONS_JSON.bak" "$VERSIONS_JSON"
      else
        printf "Error downloading the version manifest, exiting.\n"
        exit 1
      fi
    fi
  fi
}

# ---------------------------------------------------------------------------
# Get the current Minecraft version number.
#
# @param 1 The world server.
# @return The current Minecraft version number.
# ---------------------------------------------------------------------------
getCurrentMinecraftVersion() {
  local VERSION TYPE
  # Determine the version type for the current world.
  TYPE=$(getMSCSValue "$1" "mscs-version-type" "$DEFAULT_VERSION_TYPE")
  # Extract the current version information.
  VERSION=$($PERL -0777ne '
    use JSON;
    $json = decode_json ($_);
    $version = $json->{latest}{'$TYPE'};
    $version =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
    print $version;
  ' $VERSIONS_JSON)
  # Print an error and exit if the version string is empty.
  if [ -z "$VERSION" ]; then
    printf "Error detecting the current Minecraft version.\n"
    exit 1
  fi
  printf "$VERSION"
}

# ---------------------------------------------------------------------------
# Get the sha1sum for a Minecraft client or server version.
#
# @param 1 The Minecraft version.
# @param 2 The type of sha1sum needed (client, server).
# @return The sha1sum for the Minecraft client or server.
# ---------------------------------------------------------------------------
getMinecraftVersionDownloadSHA1() {
  $PERL -0777ne '
    use JSON;
    use LWP::Simple;
    my $json = decode_json ($_);
    my $version;
    foreach $ver (@{$json->{versions}}) {
      $id = $ver->{id};
      $id =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
      if ($id eq "'$1'") {
        $version = $ver;
        last;
      }
    }
    $json = decode_json (get ($version->{url}));
    print $json->{downloads}{'$2'}{sha1};
  ' $VERSIONS_JSON
}

# ---------------------------------------------------------------------------
# Get the download URL for a Minecraft client or server version.
#
# @param 1 The Minecraft version.
# @param 2 The type of download URL needed (client, server).
# @return The download URL for the Minecraft client or server.
# ---------------------------------------------------------------------------
getMinecraftVersionDownloadURL() {
  $PERL -0777ne '
    use JSON;
    use LWP::Simple;
    my $json = decode_json ($_);
    my $version;
    foreach $ver (@{$json->{versions}}) {
      $id = $ver->{id};
      $id =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
      if ($id eq "'$1'") {
        $version = $ver;
        last;
      }
    }
    $json = decode_json (get ($version->{url}));
    print $json->{downloads}{'$2'}{url};
  ' $VERSIONS_JSON
}

# ---------------------------------------------------------------------------
# Get the release time of the Minecraft version number.
#
# @param 1 The Minecraft version.
# @return The release time of the Minecraft version number.
# ---------------------------------------------------------------------------
getMinecraftVersionReleaseTime() {
  $PERL -0777ne '
    use JSON;
    $json = decode_json ($_);
    foreach $ver (@{$json->{versions}}) {
      $id = $ver->{id};
      $id =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
      print $ver->{releaseTime} if ($id eq "'$1'");
    }
  ' $VERSIONS_JSON
}

# ---------------------------------------------------------------------------
# Retrieve the version of the client for the world.
#
# @param 1 The world server.
# @return CLIENT_VERSION
# ---------------------------------------------------------------------------
getClientVersion() {
  local CURRENT_VERSION
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  # Get the client version, use the default version if not provided.
  getMSCSValue "$1" "mscs-client-version" "$DEFAULT_CLIENT_VERSION" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the .jar file name for the client for the world.
#
# @param 1 The world server.
# @return CLIENT_JAR
# ---------------------------------------------------------------------------
getClientJar() {
  local CURRENT_VERSION CLIENT_VERSION
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  CLIENT_VERSION=$(getClientVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_VERSION\n"
    exit 1
  fi
  # Get the client jar, use the default value if not provided.
  getMSCSValue "$1" "mscs-client-jar" "$DEFAULT_CLIENT_JAR" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $client_version="'$CLIENT_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$CLIENT_VERSION/$client_version/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the location of the client files for the world.
#
# @param 1 The world server.
# @return CLIENT_LOCATION
# ---------------------------------------------------------------------------
getClientLocation() {
  local CURRENT_VERSION CLIENT_VERSION
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  CLIENT_VERSION=$(getClientVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_VERSION\n"
    exit 1
  fi
  # Get the client location, use the default value if not provided.
  getMSCSValue "$1" "mscs-client-location" "$DEFAULT_CLIENT_LOCATION" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $client_version="'$CLIENT_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$CLIENT_VERSION/$client_version/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the URL to download the client for the world.
#
# @param 1 The world server.
# @return CLIENT_URL
# ---------------------------------------------------------------------------
getClientURL() {
  local CURRENT_VERSION CLIENT_VERSION URL
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  CLIENT_VERSION=$(getClientVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_VERSION\n"
    exit 1
  fi
  # Get the client download URL, use the default value if not provided.
  URL=$(getMSCSValue "$1" "mscs-client-url" "$DEFAULT_CLIENT_URL" | $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $client_version="'$CLIENT_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$CLIENT_VERSION/$client_version/g;
    $_ =~ s/\\\:/\:/g;
    print;
  ')
  # If the download URL was not specified, extract it from the version
  # manifest.
  if [ -z "$URL" ]; then
    URL=$(getMinecraftVersionDownloadURL $CLIENT_VERSION 'client')
  fi
  printf "$URL"
}

# ---------------------------------------------------------------------------
# Retrieve the version of the server running the world.
#
# @param 1 The world server.
# @return SERVER_VERSION
# ---------------------------------------------------------------------------
getServerVersion() {
  local CURRENT_VERSION
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  # Get the server version, use the default version if not provided.
  getMSCSValue "$1" "mscs-server-version" "$DEFAULT_SERVER_VERSION" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/[\s#%*+?^\${}()|[\]\\]/-/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the .jar file name for the server running the world.
#
# @param 1 The world server.
# @return SERVER_JAR
# ---------------------------------------------------------------------------
getServerJar() {
  local CURRENT_VERSION SERVER_VERSION SERVER_JAR
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  SERVER_VERSION=$(getServerVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_VERSION\n"
    exit 1
  fi
  # Get the server jar, use the default value if not provided.
  getMSCSValue "$1" "mscs-server-jar" "$DEFAULT_SERVER_JAR" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $server_version="'$SERVER_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$SERVER_VERSION/$server_version/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the location of the server files for the server running the world.
#
# @param 1 The world server.
# @return SERVER_LOCATION
# ---------------------------------------------------------------------------
getServerLocation() {
  local CURRENT_VERSION SERVER_VERSION
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  SERVER_VERSION=$(getServerVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_VERSION\n"
    exit 1
  fi
  # Get the server location, use the default value if not provided.
  getMSCSValue "$1" "mscs-server-location" "$DEFAULT_SERVER_LOCATION" |
    $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $server_version="'$SERVER_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$SERVER_VERSION/$server_version/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Retrieve the URL to download the server running the world.
#
# @param 1 The world server.
# @return SERVER_URL
# ---------------------------------------------------------------------------
getServerURL() {
  local CURRENT_VERSION SERVER_VERSION URL
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  SERVER_VERSION=$(getServerVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_VERSION\n"
    exit 1
  fi
  # Get the server download URL, use the default value if not provided.
  URL=$(getMSCSValue "$1" "mscs-server-url" "$DEFAULT_SERVER_URL" | $PERL -ne '
    $current_version="'$CURRENT_VERSION'";
    $server_version="'$SERVER_VERSION'";
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$SERVER_VERSION/$server_version/g;
    $_ =~ s/\\\:/\:/g;
    print;
  ')
  # If the download URL was not specified, extract it from the version
  # manifest.
  if [ -z "$URL" ]; then
    URL=$(getMinecraftVersionDownloadURL $SERVER_VERSION 'server')
  fi
  printf "$URL"
}

# ---------------------------------------------------------------------------
# Retrieve the command to start the server running the world.
#
# @param 1 The world server.
# @return SERVER_COMMAND
# ---------------------------------------------------------------------------
getServerCommand() {
  local CURRENT_VERSION SERVER_VERSION SERVER_JAR SERVER_LOCATION
  local SERVER_ARGS INITIAL_MEMORY MAXIMUM_MEMORY
  CURRENT_VERSION=$(getCurrentMinecraftVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CURRENT_VERSION\n"
    exit 1
  fi
  SERVER_VERSION=$(getServerVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_VERSION\n"
    exit 1
  fi
  SERVER_JAR=$(getServerJar "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_JAR\n"
    exit 1
  fi
  SERVER_LOCATION=$(getServerLocation "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_LOCATION\n"
    exit 1
  fi
  # Get the jvm arguments, use the default value if not provided.
  JVM_ARGS=$(
    getMSCSValue "$1" "mscs-jvm-args" "$DEFAULT_JVM_ARGS"
  )
  # Get the server arguments, use the default value if not provided.
  SERVER_ARGS=$(
    getMSCSValue "$1" "mscs-server-args" "$DEFAULT_SERVER_ARGS"
  )
  # Get the initial memory, use the default value if not provided.
  INITIAL_MEMORY=$(
    getMSCSValue "$1" "mscs-initial-memory" "$DEFAULT_INITIAL_MEMORY"
  )
  # Get the maximum memory, use the default value if not provided.
  MAXIMUM_MEMORY=$(
    getMSCSValue "$1" "mscs-maximum-memory" "$DEFAULT_MAXIMUM_MEMORY"
  )
  # Get the server command, use the default value if not provided.
  getMSCSValue "$1" "mscs-server-command" "$DEFAULT_SERVER_COMMAND" |
    $PERL -ne '
    $java = "'$JAVA'";
    $current_version="'$CURRENT_VERSION'";
    $server_version="'$SERVER_VERSION'";
    $jvm_args = "'$JVM_ARGS'";
    $server_jar = "'$SERVER_JAR'";
    $server_location = "'$SERVER_LOCATION'";
    $server_args = "'$SERVER_ARGS'";
    $initial_memory = "'$INITIAL_MEMORY'";
    $maximum_memory = "'$MAXIMUM_MEMORY'";
    $_ =~ s/\$JAVA/$java/g;
    $_ =~ s/\$CURRENT_VERSION/$current_version/g;
    $_ =~ s/\$SERVER_VERSION/$server_version/g;
    $_ =~ s/\$JVM_ARGS/$jvm_args/;
    $_ =~ s/\$SERVER_JAR/$server_jar/g;
    $_ =~ s/\$SERVER_LOCATION/$server_location/g;
    $_ =~ s/\$SERVER_ARGS/$server_args/g;
    $_ =~ s/\$INITIAL_MEMORY/$initial_memory/g;
    $_ =~ s/\$MAXIMUM_MEMORY/$maximum_memory/g;
    print;
  '
}

# ---------------------------------------------------------------------------
# Create a lock file for a world. This will help avoid having multiple long
# running processes running at the same time. This code was inspired by
# http://bencane.com/2015/09/22/preventing-duplicate-cron-job-executions/
#
# @param 1 The world server.
# @param 2 The type of lock file.
# @return TRUE if lock file created, FALSE otherwise.
# ---------------------------------------------------------------------------
createLockFile() {
  local PID LOCKFILE
  LOCKFILE=$WORLDS_LOCATION/$1/lock-$2.pid
  # Delete the old LOCKFILE.
  find $LOCKFILE -mmin +"$LOCKFILE_DURATION" -delete >/dev/null 2>&1
  # Check to see if the LOCKFILE exists.
  if [ -s $LOCKFILE ]; then
    PID=$(cat $LOCKFILE)
    # LOCKFILE exists, check to see if its process is running.
    ps -p $PID >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      # LOCKFILE exists and the process is running, return FALSE.
      return 1
    else
      # Process not found assume it is not running.
      echo $$ >$LOCKFILE
      if [ $? -ne 0 ]; then
        # Error creating LOCKFILE, return FALSE.
        return 1
      fi
    fi
  else
    # LOCKFILE does not exists.
    echo $$ >$LOCKFILE
    if [ $? -ne 0 ]; then
      # Error creating LOCKFILE, return FALSE.
      return 1
    fi
  fi
  # Success creating LOCKFILE, return TRUE.
  return 0
}

# ---------------------------------------------------------------------------
# Remove a lock file for a world.
#
# @param 1 The world server.
# @param 2 The type of lock file.
# ---------------------------------------------------------------------------
removeLockFile() {
  rm -f $WORLDS_LOCATION/$1/lock-$2.pid
}

# ---------------------------------------------------------------------------
# Remove old world log files and rotate log files from old servers (v < 1.7).
#
# @param 1 The world server generating the log to rotate.
# ---------------------------------------------------------------------------
rotateLog() {
  local WORLD_DIR DATE LOG NUM
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Make sure the log directory exists.
  mkdir -p "$WORLD_DIR/logs"
  if [ "$LOG_DURATION" -gt 0 ]; then
    # Delete old log files.
    find "$WORLD_DIR/logs" -type f -mtime +"$LOG_DURATION" -delete
  fi
  # Archive and rotate the log files for old Minecraft servers (Versions 1.7
  # and greater do this automatically).
  if [ -e "$WORLD_DIR/server.log" ] &&
    [ $(wc -l <$WORLD_DIR/server.log) -ge 1 ]; then
    # Make a copy of the log file in the world's logs directory.
    DATE=$(date +%F)
    cp "$WORLD_DIR/server.log" "$WORLD_DIR/logs/$DATE-0.log"
    gzip "$WORLD_DIR/logs/$DATE-0.log"
    # Empty the contents of the worlds log file.
    cp /dev/null "$WORLD_DIR/server.log"
    # Rotate the files in the world's logs directory.
    for LOG in $(ls -r $WORLD_DIR/logs/$DATE-*.log.gz); do
      NUM=$(echo $LOG | $PERL -ne 'print ($1 + 1) if ($_ =~ /'$DATE'-(\d+)/)')
      mv -f $LOG "$WORLD_DIR/logs/$DATE-$NUM.log.gz"
    done
  fi
}

# ---------------------------------------------------------------------------
# Watch the world latest.log file.
#
# @param 1 The world server generating the log to watch.
# ---------------------------------------------------------------------------
watchLog() {
  local WORLD_DIR
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Make sure that the latest.log file exists.
  if [ -e "$WORLD_DIR/logs/latest.log" ]; then
    # Watch the log file of worlds running Minecraft 1.7 +.
    tail -n0 -f --pid=$(getJavaPID "$1") $WORLD_DIR/logs/latest.log
  elif [ -e "$WORLD_DIR/server.log" ]; then
    # Watch the log file of worlds running older Minecraft servers.
    tail -n0 -f --pid=$(getJavaPID "$1") $WORLD_DIR/server.log
  fi
}

# ---------------------------------------------------------------------------
# Synchronizes the data stored in the mirror images.
#
# @param 1 The world server to sync.
# ---------------------------------------------------------------------------
syncMirrorImage() {
  # Sync the world server.
  $RSYNC -a --delete "$WORLDS_LOCATION/$1/$1/" "$WORLDS_LOCATION/$1/$1-original"
  if [ $? -ne 0 ]; then
    printf "Error synchronizing mirror images for world $1.\n"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Display the server console.
#
# @param 1 The world server to connect to.
# ---------------------------------------------------------------------------
serverConsole() {
  local LINE WORLD_DIR
  # Make sure that the world's directory exists.
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Follow the console output buffer file.
  tail -f --pid=$$ $WORLD_DIR/console.out &
  # Copy user input to the console input buffer file.
  while read LINE; do
    echo "$LINE" >>$WORLD_DIR/console.in
  done
}

# ---------------------------------------------------------------------------
# Start the world server.  Generate the appropriate environment for the
# server if it doesn't already exist.
#
# @param 1 The world server to start.
# ---------------------------------------------------------------------------
start() {
  local EULA PID SERVER_COMMAND WORLD_DIR
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Make sure that the server software exists.
  updateServerSoftware "$1"
  # Make sure that the world's directory exists.
  mkdir -p "$WORLD_DIR"
  # If the original level exists but the actual level doesn't,
  # we probably restored a backup.
  if [ -d "$WORLD_DIR/$1-original" ] && [ ! -e "$WORLD_DIR/$1" ] && [ ! -L "$WORLD_DIR/$1" ]; then
    # Restore the original world files.
    mv "$WORLD_DIR/$1-original" "$WORLD_DIR/$1"
  fi
  # Make sure that the level directory exists.
  if [ ! -e "$WORLD_DIR/$1" ] && [ ! -L "$WORLD_DIR/$1" ]; then
    mkdir -p "$WORLD_DIR/$1"
  fi
  # Make sure the EULA has been set to true.
  EULA=$(getEULAValue "$1")
  if [ $EULA != "true" ]; then
    printf "\nError, the EULA has not been accepted for world %s.\n" "$1"
    printf "To accept the EULA, modify %s/eula.txt file.\n" "$WORLD_DIR"
    exit 1
  fi
  # Rotate the world's log files.
  rotateLog "$1"
  # Make a mirror image of the world directory if requested.
  if [ $ENABLE_MIRROR -eq 1 ]; then
    # Make sure the mirror master folder exists.
    mkdir -p "$MIRROR_PATH"
    # If the symlink exists but the target doesn't, the
    # mirror was removed somehow. This is bad.
    if [ -L "$WORLD_DIR/$1" ] && [ ! -d "$MIRROR_PATH/$1" ]; then
      # Remove the symlink to the mirror image.
      rm -f "$WORLD_DIR/$1"
      # Restore the original world files.
      mv "$WORLD_DIR/$1-original" "$WORLD_DIR/$1"
      # Send notification.
      printf "Warning, the mirror for %s was removed, restored latest world.\n" $1
    fi
    # If the symlink still exists, the server was stopped outside of mscs.
    # SO DONT RESET THE MIRROR, just keep using it.
    if [ ! -L "$WORLD_DIR/$1" ]; then
      # Remove the mirror directory just in case.
      rm -Rf "$MIRROR_PATH/$1"
      # Copy the world files over to the mirror.
      cp -a "$WORLD_DIR/$1" "$MIRROR_PATH/$1"
      if [ $? -ne 0 ]; then
        printf "Error copying world data, could not copy to %s.\n" $MIRROR_PATH/$1
        exit 1
      fi
      # Remove the world file backup directory just in case.
      rm -Rf "$WORLD_DIR/$1-original"
      # Rename the original world file directory.
      mv "$WORLD_DIR/$1" "$WORLD_DIR/$1-original"
      # Create a symlink from the world file directory's original name to the mirrored files.
      ln -s "$MIRROR_PATH/$1" "$WORLD_DIR/$1"
    fi
  fi
  # Change to the world's directory.
  cd $WORLD_DIR
  # Delete any old console.in or console.out buffer files.
  rm -f "$WORLD_DIR/console.in" "$WORLD_DIR/console.out"
  # Initialize the console.in buffer file.
  printf '' >$WORLD_DIR/console.in
  # Get the server command for this world.
  SERVER_COMMAND=$(getServerCommand "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_COMMAND\n"
    exit 1
  fi
  # Start the server.
  nohup sh -c "tail -f --pid=\$$ $WORLD_DIR/console.in | {
    $SERVER_COMMAND mscs-world=$1 > $WORLD_DIR/console.out 2>&1; kill \$$;
  }" >/dev/null 2>&1 &
  # Verify the server is running.
  if [ $? -ne 0 ]; then
    printf "Error starting the server.\n"
    exit 1
  fi
  # Turn on terminal echo to work around issue with some server software.
  tty -s && tset
  # Retrieve the process ID for the server.
  sleep 1
  PID=$(getJavaPID "$1")
  if [ $PID -eq 0 ]; then
    printf "Error starting the server: couldn't retrieve the server's process ID.\n"
    exit 1
  fi
  # Start the Query handler if enabled.
  if [ "$(getServerPropertiesValue $1 'enable-query')" = "true" ]; then
    queryStart "$1"
    # Sleep for a second to workaround issue with ssh using the forced
    # pseudo-terminal allocation command line option.
    sleep 1
  fi
  # Create a PID file for the world server.
  echo $PID >"$WORLDS_LOCATION/$1.pid"
}

# ---------------------------------------------------------------------------
# Stop the world server.
#
# @param 1 The world server to stop.
# ---------------------------------------------------------------------------
stop() {
  # Tell the server to stop.
  sendCommand $1 "stop"
  sendCommand $1 "end"
  # Wait for the server to shut down.
  while serverRunning $1; do
    sleep 1
  done
  # Synchronize the mirror image of the world prior to closing, if required.
  if [ $ENABLE_MIRROR -eq 1 ] && [ -L "$WORLDS_LOCATION/$1/$1" ] && [ -d "$MIRROR_PATH/$1" ]; then
    syncMirrorImage $1
    # Remove the symlink to the world-file mirror image.
    rm -f "$WORLDS_LOCATION/$1/$1"
    # Remove the world-file mirror image folder.
    rm -Rf "$MIRROR_PATH/$1"
    # Move the world files back to their original path name.
    mv "$WORLDS_LOCATION/$1/$1-original" "$WORLDS_LOCATION/$1/$1"
  fi
  # Remove the PID file for the world server.
  rm -f "$WORLDS_LOCATION/$1.pid"
}

# ---------------------------------------------------------------------------
# Forcibly stop the world server.
#
# @param 1 The world server to forcibly stop.
# ---------------------------------------------------------------------------
forceStop() {
  local WAIT
  # Try to stop the server cleanly first.
  sendCommand $1 "stop"
  sendCommand $1 "end"
  # Wait for the server to shut down.
  WAIT=0
  while serverRunning $1 && [ $WAIT -le 20 ]; do
    WAIT=$(($WAIT + 1))
    sleep 1
  done
  # Kill the process id of the world server.
  kill -9 $(getJavaPID "$1") >/dev/null 2>&1
  # Properly clean up.
  stop $1
}

# ---------------------------------------------------------------------------
# Backup the world server.
#
# @param 1 The world server to backup.
# @return A 0 if backup successful, a 1 otherwise
# ---------------------------------------------------------------------------
worldBackup() {
  local EXCLUDE_OPTION
  # Make sure that the backup location exists.
  if ! mkdir -p "$BACKUP_LOCATION"; then
    echo "Error creating backup dir $BACKUP_LOCATION"
    return 1
  fi
  # Synchronize the mirror image of the world prior to closing, if
  # required.
  if [ $ENABLE_MIRROR -eq 1 ] && [ -L "$WORLDS_LOCATION/$1/$1" ] && [ -d "$MIRROR_PATH/$1" ]; then
    syncMirrorImage $1
  fi
  EXCLUDE_OPTION=" \
    --exclude $WORLDS_LOCATION/$1/console.out \
    --exclude $WORLDS_LOCATION/$1/query.out \
    --exclude $WORLDS_LOCATION/$1/logs/latest.log \
  "
  # Determine if we need to exclude the mirrored symlink or not
  if [ -L "$WORLDS_LOCATION/$1/$1" ]; then
    EXCLUDE_OPTION="$EXCLUDE_OPTION --exclude $WORLDS_LOCATION/$1/$1"
  fi
  # Create the backup.
  if ! $RDIFF_BACKUP -v5 --print-statistics $EXCLUDE_OPTION "$WORLDS_LOCATION/$1" "$BACKUP_LOCATION/$1" >>"$BACKUP_LOG"; then
    echo "Error doing backup of world $1"
    return 1
  fi
  # Cleanup old backups.
  if [ $BACKUP_DURATION -gt 0 ]; then
    if ! $RDIFF_BACKUP --remove-older-than ${BACKUP_DURATION}D --force "$BACKUP_LOCATION/$1" >>"$BACKUP_LOG"; then
      echo "Error cleaning old backups of world $1"
      return 1
    fi
  fi
  return 0
}

# ---------------------------------------------------------------------------
# List the backups for the world server.
#
# @param 1 The world server of interest.
# ---------------------------------------------------------------------------
worldBackupList() {
  local SEC TYPE
  if [ -d $BACKUP_LOCATION/$1 ]; then
    # Grab the list of backups for the world server.
    $RDIFF_BACKUP --parsable-output -l $BACKUP_LOCATION/$1 |
      while read SEC TYPE; do
        date --date=\@$SEC --rfc-3339=seconds | tr ' ' T
      done
  fi
}

# ---------------------------------------------------------------------------
# Restore a backup for the world server.
#
# @param 1 The world server of interest.
# @param 2 The datetime of the backup to restore.
# @return A 0 on success, a 1 otherwise.
# ---------------------------------------------------------------------------
worldBackupRestore() {
  local TARGET TARGET_TMP
  TARGET="$WORLDS_LOCATION/$1"
  TARGET_TMP="${TARGET}_bktmp"
  rm -rf "$TARGET_TMP"
  if [ -d $BACKUP_LOCATION/$1 ]; then
    if $RDIFF_BACKUP -r $2 "$BACKUP_LOCATION/$1" "$TARGET_TMP"; then
      rm -r "$TARGET"
      mv "$TARGET_TMP" "$TARGET"
    else
      echo "Restoring backup failed: $1 $2"
      rm -rf "$TARGET_TMP"
      return 1
    fi
  else
    echo "No backups found for world $1"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Update the Minecraft client software.
#
# @param 1 The world to update.
# ---------------------------------------------------------------------------
updateClientSoftware() {
  local CLIENT_JAR CLIENT_LOCATION CLIENT_URL CLIENT_VERSION SHA1 SHA1_FILE
  CLIENT_JAR=$(getClientJar "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_JAR\n"
    exit 1
  fi
  CLIENT_LOCATION=$(getClientLocation "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_LOCATION\n"
    exit 1
  fi
  CLIENT_URL=$(getClientURL "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_URL\n"
    exit 1
  fi
  CLIENT_VERSION=$(getClientVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$CLIENT_VERSION\n"
    exit 1
  fi
  # Make sure the client software directory exists.
  mkdir -p "$CLIENT_LOCATION"
  # Download the client jar if it is missing.
  if [ ! -s "$CLIENT_LOCATION/$CLIENT_JAR" ]; then
    # Download the Minecraft client software.
    $WGET -qO "$CLIENT_LOCATION/$CLIENT_JAR" "$CLIENT_URL"
    # Report any errors.
    if [ $? -ne 0 ]; then
      printf "Error downloading the Minecraft client software.\n"
      exit 1
    fi
    SHA1=$(getMinecraftVersionDownloadSHA1 $CLIENT_VERSION 'client')
    if [ -z $SHA1 ]; then
      printf "Error retrieving the sha1 for the Minecraft client software.\n"
      exit 1
    fi
    SHA1_FILE=$(sha1sum $CLIENT_LOCATION/$CLIENT_JAR | cut -d ' ' -f1)
    if [ $SHA1 != "$SHA1_FILE" ]; then
      printf "Error verifying the sha1 for the Minecraft client software.\n"
      exit 1
    fi
  fi
}

# ---------------------------------------------------------------------------
# Update the Minecraft server software.
#
# @param 1 The world server to update.
# ---------------------------------------------------------------------------
updateServerSoftware() {
  local SERVER_JAR SERVER_LOCATION SERVER_URL SERVER_VERSION SHA1 SHA1_FILE
  SERVER_JAR=$(getServerJar "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_JAR\n"
    exit 1
  fi
  SERVER_LOCATION=$(getServerLocation "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_LOCATION\n"
    exit 1
  fi
  SERVER_URL=$(getServerURL "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_URL\n"
    exit 1
  fi
  SERVER_VERSION=$(getServerVersion "$1")
  if [ $? -ne 0 ]; then
    printf "$SERVER_VERSION\n"
    exit 1
  fi
  # Make sure the server software directory exists.
  mkdir -p "$SERVER_LOCATION"
  # Download the server jar if it is missing.
  if [ ! -s "$SERVER_LOCATION/$SERVER_JAR" ]; then
    # Download the Minecraft server software.
    $WGET -qO "$SERVER_LOCATION/$SERVER_JAR" "$SERVER_URL"
    # Report any errors.
    if [ $? -ne 0 ]; then
      printf "Error updating the Minecraft server software.\n"
      exit 1
    fi
    SHA1=$(getMinecraftVersionDownloadSHA1 $SERVER_VERSION 'server')
    if [ -z $SHA1 ]; then
      printf "Error retrieving the sha1 for the Minecraft server software.\n"
      exit 1
    fi
    SHA1_FILE=$(sha1sum $SERVER_LOCATION/$SERVER_JAR | cut -d ' ' -f1)
    if [ $SHA1 != "$SHA1_FILE" ]; then
      printf "Error verifying the sha1 for the Minecraft server software.\n"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Run Minecraft Overviewer mapping software on the world.  Generates an
# index.html file using the Google Maps API.
#
# @param 1 The world server to map with Overviewer.
# ---------------------------------------------------------------------------
overviewer() {
  local SETTINGS_FILE LOG_FILE VERSION_TEST
  SETTINGS_FILE="$WORLDS_LOCATION/$1/overviewer-settings.py"
  LOG_FILE="$WORLDS_LOCATION/$1/logs/overviewer.log"
  VERSION_TEST=$(compareMinecraftVersions $(getServerVersion $1) 1.7.2)
  # Make sure this world has a server.properties file before mapping.
  if [ ! -e "$WORLDS_LOCATION/$1/server.properties" ]; then
    return
  fi
  # Make sure that the backup of the world files are there before mapping.
  if [ ! -e "$BACKUP_LOCATION/$1/server.properties" ]; then
    printf "\nError finding the backup for world $1.  To save server "
    printf "down time, mapping is run from the backup location.\n"
    printf "Run '$PROG backup $1' before mapping.\n"
    return
  fi
  # Make sure the maps directory exists.
  mkdir -p "$MAPS_LOCATION/$1"
  # Make sure the Minecraft client is available.
  updateClientSoftware "$1"
  # Create a default Overviewer settings file if it is missing.
  if [ ! -e $SETTINGS_FILE ]; then
    # Use the backup location so we minimize the time the server isn't saving data.
    printf "import os\n\n" >$SETTINGS_FILE
    printf "worlds['$1'] = '$BACKUP_LOCATION/$1/$1-original' if os.path.exists('$BACKUP_LOCATION/$1/$1-original') else '$BACKUP_LOCATION/$1/$1'\n\n" >>$SETTINGS_FILE
    printf "renders['overworld-render'] = {\n" >>$SETTINGS_FILE
    printf "  'world': '$1',\n" >>$SETTINGS_FILE
    printf "  'title': 'Overworld',\n" >>$SETTINGS_FILE
    printf "  'dimension': 'overworld',\n" >>$SETTINGS_FILE
    printf "  'rendermode': 'normal'\n" >>$SETTINGS_FILE
    printf "}\n\n" >>$SETTINGS_FILE
    printf "renders['overworld-caves-render'] = {\n" >>$SETTINGS_FILE
    printf "  'world': '$1',\n" >>$SETTINGS_FILE
    printf "  'title': 'Caves',\n" >>$SETTINGS_FILE
    printf "  'dimension': 'overworld',\n" >>$SETTINGS_FILE
    printf "  'rendermode': 'cave'\n" >>$SETTINGS_FILE
    printf "}\n\n" >>$SETTINGS_FILE
    printf "renders['nether-render'] = {\n" >>$SETTINGS_FILE
    printf "  'world': '$1',\n" >>$SETTINGS_FILE
    printf "  'title': 'Nether',\n" >>$SETTINGS_FILE
    printf "  'dimension': 'nether',\n" >>$SETTINGS_FILE
    printf "  'rendermode': 'nether'\n" >>$SETTINGS_FILE
    printf "}\n\n" >>$SETTINGS_FILE
    printf "renders['end-render'] = {\n" >>$SETTINGS_FILE
    printf "  'world': '$1',\n" >>$SETTINGS_FILE
    printf "  'title': 'End',\n" >>$SETTINGS_FILE
    printf "  'dimension': 'end',\n" >>$SETTINGS_FILE
    printf "  'rendermode': 'normal'\n" >>$SETTINGS_FILE
    printf "}\n\n" >>$SETTINGS_FILE
    printf "processes = 2\n" >>$SETTINGS_FILE
    printf "outputdir = '$MAPS_LOCATION/$1'\n" >>$SETTINGS_FILE
  fi
  # Announce the mapping of the world to players if the world is running.
  if serverRunning $1; then
    if [ $VERSION_TEST -ge 0 ]; then
      sendCommand $1 'tellraw @a {
        "text" : "",
        "extra" : [
          {
            "text" : "[Server] The world is about to be mapped with "
          },
          {
            "text" : "Overviewer",
            "color" : "aqua",
            "clickEvent" : {
              "action" : "open_url",
              "value" : "'$OVERVIEWER_URL'"
            }
          },
          {
            "text" : "."
          }
        ]
      }'
    else
      sendCommand $1 "say The world is about to be mapped with Overviewer."
    fi
  fi
  # Generate the map and POI.
  $OVERVIEWER_BIN --config=$SETTINGS_FILE >>$LOG_FILE 2>&1
  $OVERVIEWER_BIN --config=$SETTINGS_FILE --genpoi >>$LOG_FILE 2>&1
  # Announce the location to access the world map to players.
  if serverRunning $1; then
    if [ $VERSION_TEST -ge 0 ]; then
      sendCommand $1 'tellraw @a {
        "text" : "",
        "extra" : [
          {
            "text" : "[Server] Mapping is complete. You can access the maps "
          },
          {
            "text" : "here",
            "color" : "aqua",
            "clickEvent" : {
              "action" : "open_url",
              "value" : "'$MAPS_URL'/'$1'"
            }
          },
          {
            "text" : "."
          }
        ]
      }'
    else
      sendCommand $1 "say Mapping is complete.  You can access the maps at:"
      sendCommand $1 "say $MAPS_URL/$1"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Start a Query handler for a world server.
#
# @param 1 The world server to start a Query handler for.
# ---------------------------------------------------------------------------
queryStart() {
  local WORLD_DIR SERVER_IP SERVER_PID QUERY_PORT
  # Grab the location of the world's directory.
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Determine the IP address and port used by the query server.
  SERVER_IP=$(getServerPropertiesValue $1 'server-ip' '127.0.0.1')
  QUERY_PORT=$(getServerPropertiesValue $1 'query.port')
  SERVER_PID=$(getJavaPID $1)
  # Delete any old query.in or query.out buffer files.
  rm -Rf "$WORLD_DIR/query.in" "$WORLD_DIR/query.out"
  # Initialize the query.in and query.out buffer files.
  printf '' >"$WORLD_DIR/query.in"
  printf '' >"$WORLD_DIR/query.out"
  # Start a tail process to watch for changes to the query.in file to pipe
  # to the Minecraft query server via socat.  The response from the query
  # server is piped into the query.out file.  Give the server a moment to
  # start before initializing the Query handler.
  nohup sh -c "
    sleep 20;
    tail -f --pid=$SERVER_PID \"$WORLD_DIR/query.in\" |
    $SOCAT - UDP:$SERVER_IP:$QUERY_PORT > \"$WORLD_DIR/query.out\"
  " >/dev/null 2>&1 &
  # Verify the connection to the query server worked.
  if [ $? -ne 0 ]; then
    printf "Error connecting to the query server.\n"
  fi
}

# ---------------------------------------------------------------------------
# Pack a hex string into a buffer file that is piped to the Minecraft query
# server.
#
# @param 1 The world server of interest.
# @param 2 The packet type.
# @param 3 The packet payload.
# @param 4 The response format.
# @return The response from the Query server in the requested format.
# ---------------------------------------------------------------------------
querySendPacket() {
  local ID PACKET RESPONSE WORLD_DIR
  # The packet identifier.
  ID="00000001"
  # The world's directory.
  WORLD_DIR="$WORLDS_LOCATION/$1"
  # Make sure the query.in and query.out buffer files exist before
  # preparing and sending the packet to the Query server.
  if [ -e "$WORLD_DIR/query.in" ] && [ -e "$WORLD_DIR/query.out" ]; then
    # Add the magic bytes and create the hex string packet.
    PACKET=$(printf "FEFD%s%s%s" "$2" "$ID" "$3")
    # Remove any old responses from the query.out buffer file.
    printf '' >"$WORLD_DIR/query.out"
    # Pack the hex string packet and write it to the query.in buffer file.
    $PERL -e "
      print map { pack (\"C\", hex(\$_)) } (\"$PACKET\" =~ /(..)/g);
    " >>"$WORLD_DIR/query.in"
    # Give the Query server a moment to respond.
    sleep 1
    # Unpack the response packet from the query.out buffer file. There are a
    # variable amount of null bytes at the start of the response packet, so
    # find the start of the response by searching for the packet type and ID.
    RESPONSE=$($PERL -0777 -ne '
      foreach (unpack "C*", $_) {
        $char = sprintf ("%.2x", $_);
        $char =~ s/0a/5c6e/;
        $hex .= $char;
      }
      $hex =~ s/^0*'$2$ID'/'$2$ID'/;
      print $hex;
    ' $WORLD_DIR/query.out)
  fi
  if [ -n "$RESPONSE" ]; then
    # Return the response in the format requested.
    $PERL -e '
      $packed = join "", map { pack ("C", hex($_)) } ("'$RESPONSE'" =~ /(..)/g);
      printf "%s\n", join "\t", unpack ("'$4'", $packed);
    '
  fi
}

# ---------------------------------------------------------------------------
# Send a challenge packet to the Minecraft query server.
#
# @param 1 The world server of interest.
# @return Tab separated values:
#           type       - The packet type.
#           id         - The packet identifier.
#           token      - The token.
# ---------------------------------------------------------------------------
querySendChallengePacket() {
  local PACKET
  # Use an empty packet.
  PACKET="00000000"
  # Send the challenge packet to the Minecraft query server.
  querySendPacket "$1" "09" "$PACKET" "Cl>Z*"
}

# ---------------------------------------------------------------------------
# Send a status query to the Minecraft query server.
#
# @param 1 The world server of interest.
# @return Tab separated values:
#           type       - The packet type.
#           id         - The packet identifier.
#           MOTD       - The world's message of the day.
#           gametype   - The world's game type.
#           map        - The name of the world.
#           numplayers - The current number of players.
#           maxplayers - The maximum number of players.
#           hostport   - The host's port
#           hostip     - The host's IP address.
# ---------------------------------------------------------------------------
queryStatus() {
  local PACKET TOKEN
  if [ "$(getServerPropertiesValue $1 'enable-query')" = "true" ]; then
    # Send a challenge packet to the Minecraft query server.
    TOKEN=$(querySendChallengePacket $1 | cut -f 3)
    if [ -n "$TOKEN" ]; then
      # Use the challenge token for the packet.
      PACKET=$(printf "%08x" $TOKEN)
      # Send the information request packet to the Minecraft query server.
      querySendPacket "$1" "00" "$PACKET" "Cl>Z*Z*Z*Z*Z*s<Z*"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Send a detailed status query to the Minecraft query server.
#
# @param 1 The world server of interest.
# @return Tab separated values:
#           type       - The packet type.
#           id         - The packet identifier.
#           *          - The string 'splitnum'.
#           *          - The value 128.
#           *          - The value 0.
#           *          - The string 'hostname'.
#           MOTD       - The world's message of the day.
#           *          - The string 'gametype'.
#           gametype   - The world's game type, hardcoded to 'SMP'.
#           *          - The string 'game_id'.
#           gameid     - The world's game ID, hardcoded to 'MINECRAFT'.
#           *          - The string 'version'.
#           version    - The world's Minecraft version.
#           *          - The string 'plugins'.
#           plugins    - The world's plugins.
#           *          - The string 'map'.
#           map        - The world's name.
#           *          - The string 'numplayers'.
#           numplayers - The world's current number of players.
#           *          - The string 'maxplayers'.
#           maxplayers - The world's maximum number of players.
#           *          - The string 'hostport'.
#           hostport   - The world's host port.
#           *          - The string 'hostip'.
#           hostip     - The world's host IP address.
#           *          - The value 0.
#           *          - The value 1.
#           *          - The string 'player_'.
#           *          - The value 0.
#           players    - The players currently logged onto the world.
# ---------------------------------------------------------------------------
queryDetailedStatus() {
  local CHALLENGE ID PACKET TOKEN
  if [ "$(getServerPropertiesValue $1 'enable-query')" = "true" ]; then
    # Send a challenge packet to the Minecraft query server.
    CHALLENGE=$(querySendChallengePacket $1)
    ID=$(echo "$CHALLENGE" | cut -f 2)
    TOKEN=$(echo "$CHALLENGE" | cut -f 3)
    if [ -n "$ID" ] && [ -n "$TOKEN" ]; then
      # Use the challenge token for the packet, with the ID on the end.
      PACKET=$(printf "%08x%08x" $TOKEN $ID)
      # Send the information request packet to the Minecraft query server.
      querySendPacket "$1" "00" "$PACKET" \
        "Cl>Z*CCZ*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*Z*CCZ*C(Z*)*"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Send a detailed status query to the Minecraft query server and return the
# data in JSON format.
#
# @param 1 The world server of interest.
# @return Query values in JSON format.
# ---------------------------------------------------------------------------
queryDetailedStatusJSON() {
  local STATUS JSON MOTD GAMETYPE GAMEID VERSION PLUGINS MAP NUMPLAYERS MAXPLAYERS HOSTPORT HOSTIP PLAYERS COUNTER
  STATUS=$(queryDetailedStatus $1)
  if [ -n "$STATUS" ]; then
    MOTD=$(printf "%s" "$STATUS" | cut -f 7)
    GAMETYPE=$(printf "%s" "$STATUS" | cut -f 9)
    GAMEID=$(printf "%s" "$STATUS" | cut -f 11)
    VERSION=$(printf "%s" "$STATUS" | cut -f 13)
    PLUGINS=$(printf "%s" "$STATUS" | cut -f 15)
    MAP=$(printf "%s" "$STATUS" | cut -f 17)
    NUMPLAYERS=$(printf "%s" "$STATUS" | cut -f 19)
    MAXPLAYERS=$(printf "%s" "$STATUS" | cut -f 21)
    HOSTPORT=$(printf "%s" "$STATUS" | cut -f 23)
    HOSTIP=$(printf "%s" "$STATUS" | cut -f 25)
    if [ $NUMPLAYERS -gt 0 ]; then
      PLAYERS=$(printf "%s\"" "$PLAYERS" $(printf "%s" "$STATUS" | cut -f $((30))))
      COUNTER=1
      while [ $COUNTER -lt $NUMPLAYERS ]; do
        PLAYERS=$(printf "%s, \"%s\"" "$PLAYERS" $(printf "%s" "$STATUS" | cut -f $((30 + $COUNTER))))
        COUNTER=$(($COUNTER + 1))
      done
    fi
    JSON="{\"motd\":\"$MOTD\",\"gametype\":\"$GAMETYPE\",\"gameid\":\"$GAMEID\",\"version\":\"$VERSION\",\"plugins\":\"$PLUGINS\",\"map\":\"$MAP\",\"numplayers\":$NUMPLAYERS,\"maxplayers\":$MAXPLAYERS,\"hostport\":\"$HOSTPORT\",\"hostip\":\"$HOSTIP\",\"players\":[$PLAYERS]}"
  else
    JSON="{}"
  fi
  printf "%s" "$JSON"
}

# ---------------------------------------------------------------------------
# Query the number of active users from the query server.
#
# @param 1 The world server of interest.
# @return Number of active users.
# ---------------------------------------------------------------------------
queryNumUsers() {
  local NUM_USERS
  NUM_USERS=$(queryStatus $1 | cut -f6)
  # Return 0 if query server not available
  [ -z "$NUM_USERS" ] && NUM_USERS=0
  printf "$NUM_USERS"
}

# ---------------------------------------------------------------------------
# Display the status of a Minecraft world server.
#
# @param 1 The world server of interest.
# ---------------------------------------------------------------------------
worldStatus() {
  local STATUS NUM MAX PLAYERS COUNTER VERSION
  if serverRunning $1; then
    STATUS=$(queryDetailedStatus $1)
    if [ -n "$STATUS" ]; then
      NUM=$(printf "%s" "$STATUS" | cut -f 19)
      MAX=$(printf "%s" "$STATUS" | cut -f 21)
      VERSION=$(printf "%s" "$STATUS" | cut -f 13)
      printf "running version %s (%d of %d users online).\n" "$VERSION" $NUM $MAX
      if [ $NUM -gt 0 ]; then
        PLAYERS=$(printf "%s" $(printf "%s" "$STATUS" | cut -f 30))
        COUNTER=1
        while [ $COUNTER -lt $NUM ]; do
          PLAYERS=$(printf "%s, %s" "$PLAYERS" $(printf "%s" "$STATUS" | cut -f $((30 + $COUNTER))))
          COUNTER=$(($COUNTER + 1))
        done
        printf "    Players: %s.\n" "$PLAYERS"
      fi
    elif [ "$(getServerPropertiesValue $1 'enable-query')" = "true" ]; then
      printf "running (query server offline).\n"
    else
      printf "running.\n"
    fi
    printf "    Process ID: %d.\n" $(getJavaPID "$1")
    printf "    Memory used: %d kB.\n" $(getJavaMemory "$1")
  elif [ "$(getMSCSValue $1 'mscs-enabled')" = "false" ]; then
    printf "disabled.\n"
  else
    printf "not running.\n"
  fi
}

# ---------------------------------------------------------------------------
# Display the status of a Minecraft world server in JSON format.
#
# @param 1 The world server of interest.
# @return The status of the world in JSON format.
# ---------------------------------------------------------------------------
worldStatusJSON() {
  local RUNNING QUERY PID MEMORY
  if serverRunning $1; then
    RUNNING="true"
    QUERY="$(queryDetailedStatusJSON $1)"
    PID="$(getJavaPID $1)"
    MEMORY="$(getJavaMemory $1)"
  else
    RUNNING="false"
    QUERY="null"
    PID="null"
    MEMORY="null"
  fi
  printf "{\"running\":%s,\"query\":%s,\"pid\":%s,\"memory\":%s}" "$RUNNING" "$QUERY" "$PID" "$MEMORY"
}

# ---------------------------------------------------------------------------
# Begin.
# ---------------------------------------------------------------------------

# Make sure that Java, Perl, libjson-perl, libwww-perl, Python, Wget,
# Rdiff-backup, Rsync, and Socat are installed.
# ---------------------------------------------------------------------------
if [ ! -e "$JAVA" ]; then
  echo "ERROR: Java not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install default-jre"
  exit 1
fi
if [ ! -e "$PERL" ]; then
  echo "ERROR: Perl not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install perl"
  exit 1
fi
$PERL -e 'use JSON;' >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: libjson-perl not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install libjson-perl"
  exit 1
fi
$PERL -e 'use LWP::Simple;' >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: libwww-perl not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install libwww-perl"
  exit 1
fi
$PERL -e 'use LWP::Protocol::https;' >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: liblwp-protocol-https-perl not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install liblwp-protocol-https-perl"
  exit 1
fi
if [ ! -e "$PYTHON" ]; then
  echo "ERROR: Python not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install python"
  exit 1
fi
if [ ! -e "$WGET" ]; then
  echo "ERROR: GNU Wget not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install wget"
  exit 1
fi
if [ ! -e "$RDIFF_BACKUP" ]; then
  echo "ERROR: rdiff-backup not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install rdiff-backup"
  exit 1
fi
if [ ! -e "$RSYNC" ]; then
  echo "ERROR: rsync not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install rsync"
  exit 1
fi
if [ ! -e "$SOCAT" ]; then
  echo "ERROR: socat not found!"
  echo "Try installing this with:"
  echo "sudo apt-get install socat"
  exit 1
fi

# Parse command-line options
# ---------------------------------------------------------------------------
while [ "$1" != "${1#-}" ]; do
  case "$1" in
    -p)
      if [ -n "$2" ]; then
        PROG="$2"
        shift
      else
        echo "$PROG: '-p' needs a program name argument."
        exit 1
      fi
      ;;
    -c)
      if [ -n "$2" ]; then
        MSCS_DEFAULTS_CL="$2"
        shift
      else
        echo "$PROG: '-c' needs a config file argument."
        exit 1
      fi
      ;;
    -l)
      if [ -n "$2" ]; then
        LOCATION_CL="$2"
        shift
      else
        echo "$PROG: '-l' needs a location path argument."
        exit 1
      fi
      ;;
    *)
      echo "$PROG: unknown option '$1'."
      echo "Execute '$PROG' without arguments for usage instructions."
      exit 1
      ;;
  esac
  shift
done

# Override Default Values
# ---------------------------------------------------------------------------
# Override the default values by adding them to one of the following files. If
# none of the files exist, the default values in the script will be used (see
# below) and an example file will be created at `$HOME/mscs.defaults`.
# Possible files are checked in the following order:
#   command line option "-c".
#   $HOME/mscs.defaults
#   $HOME/.config/mscs/mscs.defaults
if [ -n "$MSCS_DEFAULTS_CL" ]; then
  MSCS_DEFAULTS="$MSCS_DEFAULTS_CL"
elif [ -r "$HOME/mscs.defaults" ]; then
  MSCS_DEFAULTS="$HOME/mscs.defaults"
elif [ -r "$HOME/.config/mscs/mscs.defaults" ]; then
  MSCS_DEFAULTS="$HOME/.config/mscs/mscs.defaults"
else
  MSCS_DEFAULTS="$HOME/mscs.defaults"
fi
# Generate the example `mscs.defaults` if it is missing or empty.
if [ ! -s "$MSCS_DEFAULTS" ]; then
  mscs_defaults >$MSCS_DEFAULTS
fi
# Default values in the script can be overridden by adding certain key/value
# pairs to one of the mscs.defaults files mentioned above. Default values in
# the script will be used unless overridden in one these files.
#
# The following keys are available:
#   mscs-location                - Location of the mscs files.
#   mscs-worlds-location         - Location of world files.
#   mscs-versions-url            - URL to download the version_manifest.json file.
#   mscs-versions-json           - Location of the version_manifest.json file.
#   mscs-versions-duration       - Duration (in minutes) to keep the version_manifest.json file before updating.
#   mscs-lockfile-duration       - Duration (in minutes) to keep lock files before removing.
#   mscs-detailed-listing        - Properties to return for detailed listings.
#   mscs-default-world           - Default world name.
#   mscs-default-port            - Default Port.
#   mscs-default-ip              - Default IP address.
#   mscs-default-version-type    - Default version type (release or snapshot).
#   mscs-default-client-version  - Default version of the client software.
#   mscs-default-client-jar      - Default .jar file for the client software.
#   mscs-default-client-url      - Default download URL for the client software.
#   mscs-default-client-location - Default location of the client .jar file.
#   mscs-default-server-version  - Default version of the server software.
#   mscs-default-jvm-args        - Default arguments for the JVM.
#   mscs-default-server-jar      - Default .jar file for the server software.
#   mscs-default-server-url      - Default download URL for the server software.
#   mscs-default-server-args     - Default arguments for a world server.
#   mscs-default-initial-memory  - Default initial amount of memory for a world server.
#   mscs-default-maximum-memory  - Default maximum amount of memory for a world server.
#   mscs-default-server-location - Default location of the server .jar file.
#   mscs-default-server-command  - Default command to run for a world server.
#   mscs-backup-location         - Location to store backup files.
#   mscs-backup-log              - Lcation of the backup log file.
#   mscs-backup-duration         - Length in days that backups survive.
#   mscs-log-duration            - Length in days that logs survive.
#   mscs-enable-mirror           - Enable the mirror option by default for worlds (default disabled).
#   mscs-mirror-path             - Default path for the mirror files.
#   mscs-overviewer-bin          - Location of Overviewer.
#   mscs-overviewer-url          - URL for Overviewer.
#   mscs-maps-location           - Location of Overviewer generated map files.
#   mscs-maps-url                - URL for accessing Overviewer generated maps.
#
# The following variables may be used in some of the key values:
#   $JAVA                - The Java virtual machine.
#   $CURRENT_VERSION     - The current Mojang Minecraft release version.
#   $CLIENT_VERSION      - The version of the client software.
#   $SERVER_VERSION      - The version of the server software.
#   $SERVER_JAR          - The .jar file to run for the server.
#   $SERVER_ARGS         - The arguments to the server.
#   $INITIAL_MEMORY      - The initial amount of memory for the server.
#   $MAXIMUM_MEMORY      - The maximum amount of memory for the server.
#   $SERVER_LOCATION     - The location of the server .jar file.
#
# The following example key/value pairs are equivalent to the default values:
#   mscs-location=/opt/mscs
#   mscs-worlds-location=/opt/mscs/worlds
#   mscs-versions-url=https://launchermeta.mojang.com/mc/game/version_manifest.json
#   mscs-versions-json=/opt/mscs/version_manifest.json
#   mscs-versions-duration=30
#   mscs-lockfile-duration=1440
#   mscs-default-world=world
#   mscs-default-port=25565
#   mscs-default-ip=
#   mscs-default-version-type=release
#   mscs-default-client-version=$CURRENT_VERSION
#   mscs-default-client-jar=$CLIENT_VERSION.jar
#   mscs-default-client-url=
#   mscs-default-client-location=/opt/mscs/.minecraft/versions/$CLIENT_VERSION
#   mscs-default-server-version=$CURRENT_VERSION
#   mscs-default-jvm-args=
#   mscs-default-server-jar=minecraft_server.$SERVER_VERSION.jar
#   mscs-default-server-url=
#   mscs-default-server-args=nogui
#   mscs-default-initial-memory=128M
#   mscs-default-maximum-memory=2048M
#   mscs-default-server-location=/opt/mscs/server
#   mscs-default-server-command=$JAVA -Xms$INITIAL_MEMORY -Xmx$MAXIMUM_MEMORY -jar $SERVER_LOCATION/$SERVER_JAR $SERVER_ARGS
#   mscs-backup-location=/opt/mscs/backups
#   mscs-backup-log=/opt/mscs/backups/backup.log
#   mscs-backup-duration=15
#   mscs-log-duration=15
#   mscs-detailed-listing=motd server-ip server-port max-players level-type online-mode
#   mscs-enable-mirror=0
#   mscs-mirror-path=/dev/shm/mscs
#   mscs-overviewer-bin=/usr/bin/overviewer.py
#   mscs-overviewer-url=http://overviewer.org
#   mscs-maps-location=/opt/mscs/maps
#   mscs-maps-url=http://minecraft.server.com/maps

# Server Location
# ---------------------------------------------------------------------------
# The default location of server software and data.
LOCATION=$(getDefaultsValue 'mscs-location' $HOME'/mscs')
# Override with command-line location option.
[ -n "$LOCATION_CL" ] && LOCATION="$LOCATION_CL"

# Global Server Configuration
# ---------------------------------------------------------------------------

# Minecraft Versions information
# ---------------------------------------------------------------------------
MINECRAFT_VERSIONS_URL=$(getDefaultsValue 'mscs-versions-url' 'https://launchermeta.mojang.com/mc/game/version_manifest.json')

# Minecraft Server Settings
# ---------------------------------------------------------------------------
# Settings used if not provided in the world's mscs.properties file.
DEFAULT_WORLD=$(getDefaultsValue 'mscs-default-world' 'world')
DEFAULT_PORT=$(getDefaultsValue 'mscs-default-port' '25565')
DEFAULT_IP=$(getDefaultsValue 'mscs-default-ip' '')
DEFAULT_VERSION_TYPE=$(getDefaultsValue 'mscs-default-version-type' 'release')
DEFAULT_CLIENT_VERSION=$(getDefaultsValue 'mscs-default-client-version' '$CURRENT_VERSION')
DEFAULT_CLIENT_JAR=$(getDefaultsValue 'mscs-default-client-jar' '$CLIENT_VERSION.jar')
DEFAULT_CLIENT_URL=$(getDefaultsValue 'mscs-default-client-url' '')
DEFAULT_CLIENT_LOCATION=$(getDefaultsValue 'mscs-default-client-location' $HOME'/.minecraft/versions/$CLIENT_VERSION')
DEFAULT_SERVER_VERSION=$(getDefaultsValue 'mscs-default-server-version' '$CURRENT_VERSION')
DEFAULT_JVM_ARGS=$(getDefaultsValue 'mscs-default-jvm-args' '')
DEFAULT_SERVER_JAR=$(getDefaultsValue 'mscs-default-server-jar' 'minecraft_server.$SERVER_VERSION.jar')
DEFAULT_SERVER_URL=$(getDefaultsValue 'mscs-default-server-url' '')
DEFAULT_SERVER_ARGS=$(getDefaultsValue 'mscs-default-server-args' 'nogui')
DEFAULT_INITIAL_MEMORY=$(getDefaultsValue 'mscs-default-initial-memory' '128M')
DEFAULT_MAXIMUM_MEMORY=$(getDefaultsValue 'mscs-default-maximum-memory' '2048M')
DEFAULT_SERVER_LOCATION=$(getDefaultsValue 'mscs-default-server-location' $LOCATION'/server')
DEFAULT_SERVER_COMMAND=$(getDefaultsValue 'mscs-default-server-command' '$JAVA -Xms$INITIAL_MEMORY -Xmx$MAXIMUM_MEMORY $JVM_ARGS -jar $SERVER_LOCATION/$SERVER_JAR $SERVER_ARGS')
# Each world server can override the default values in a similar manner by
# adding certain key/value pairs to the world's mscs.properties file.
#
# The following keys are available:
#   mscs-enabled         - Enable or disable the world server.
#   mscs-version-type    - Assign the version type (release or snapshot).
#   mscs-client-version  - Assign the version of the client software.
#   mscs-client-jar      - Assign the .jar file for the client software.
#   mscs-client-url      - Assign the download URL for the client software.
#   mscs-client-location - Assign the location of the client .jar file.
#   mscs-server-version  - Assign the version of the server software.
#   mscs-jvm-args        - Assign the arguments to the JVM.
#   mscs-server-jar      - Assign the .jar file for the server software.
#   mscs-server-url      - Assign the download URL for the server software.
#   mscs-server-args     - Assign the arguments to the server.
#   mscs-initial-memory  - Assign the initial amount of memory for the server.
#   mscs-maximum-memory  - Assign the maximum amount of memory for the server.
#   mscs-server-location - Assign the location of the server .jar file.
#   mscs-server-command  - Assign the command to run for the server.
#
# Like above, the following variables may be used in some of the key values:
#   $JAVA                - The Java virtual machine.
#   $CURRENT_VERSION     - The current Mojang Minecraft release version.
#   $CLIENT_VERSION      - The version of the client software.
#   $SERVER_VERSION      - The version of the server software.
#   $JVM_ARGS            - The arguments to the JVM.
#   $SERVER_JAR          - The .jar file to run for the server.
#   $SERVER_ARGS         - The arguments to the server.
#   $INITIAL_MEMORY      - The initial amount of memory for the server.
#   $MAXIMUM_MEMORY      - The maximum amount of memory for the server.
#   $SERVER_LOCATION     - The location of the server .jar file.
#
# The following example key/value pairs are equivalent to the default values:
#   mscs-enabled=true
#   mscs-version-type=release
#   mscs-client-version=$CURRENT_VERSION
#   mscs-client-jar=$CLIENT_VERSION.jar
#   mscs-client-url=
#   mscs-client-location=/opt/mscs/.minecraft/versions/$CLIENT_VERSION
#   mscs-server-version=$CURRENT_VERSION
#   mscs-jvm-args=
#   mscs-server-jar=minecraft_server.$SERVER_VERSION.jar
#   mscs-server-url=
#   mscs-server-args=nogui
#   mscs-initial-memory=128M
#   mscs-maximum-memory=2048M
#   mscs-server-location=/opt/mscs/server
#   mscs-server-command=$JAVA -Xms$INITIAL_MEMORY -Xmx$MAXIMUM_MEMORY -jar $SERVER_LOCATION/$SERVER_JAR $SERVER_ARGS

# World (Server Instance) Configuration
# ---------------------------------------------------------------------------
# The location to store files for each world server.
WORLDS_LOCATION=$(getDefaultsValue 'mscs-worlds-location' $LOCATION'/worlds')
# The location to store the version_manifest.json file.
VERSIONS_JSON=$(getDefaultsValue 'mscs-versions-json' $LOCATION'/version_manifest.json')
# The duration (in minutes) to keep the version_manifest.json file before updating.
VERSIONS_DURATION=$(getDefaultsValue 'mscs-versions-duration' '30')
# The duration (in minutes) to keep lock files before removing.
LOCKFILE_DURATION=$(getDefaultsValue 'mscs-lockfile-duration' '1440')

# Backup Configuration
# ---------------------------------------------------------------------------
# Location to store backups.
BACKUP_LOCATION=$(getDefaultsValue 'mscs-backup-location' $LOCATION'/backups')
# Location of the backup log file.
BACKUP_LOG=$(getDefaultsValue 'mscs-backup-log' $BACKUP_LOCATION'/backup.log')
# Length in days that backups survive.
BACKUP_DURATION=$(getDefaultsValue 'mscs-backup-duration' '15')

# Server Log Configuration
# ---------------------------------------------------------------------------
# Length in days that logs survive.
LOG_DURATION=$(getDefaultsValue 'mscs-log-duration' '15')

# Listing options
# ---------------------------------------------------------------------------
# Server properties for detailed listing (list).
DETAILED_LISTING_PROPERTIES=$(getDefaultsValue 'mscs-detailed-listing' 'motd server-ip server-port max-players level-type online-mode')

# Mirror Image Options
# ---------------------------------------------------------------------------
# Create a mirror image of the world data on system startup, and
# update that mirror image on system shutdown.
#
# IMPORTANT: If using this option, the admin should schedule
# periodic synchronizations of the mirror image using cron
# to avoid data loss. To do this, add a cron task to call
# the "sync" option on a VERY regular basis (e.g.,
# every 5-10 minutes).
#
# 0 - Do not use a mirror image, default.
# 1 - Use a mirror image.
ENABLE_MIRROR=$(getDefaultsValue 'mscs-enable-mirror' '0')
# The location to store the mirror image.
#
# NOTE: This is usually a ramdisk, e.g. /dev/shm on Debian/Ubuntu.
MIRROR_PATH=$(getDefaultsValue 'mscs-mirror-path' '/dev/shm/mscs')

# Minecraft Overviewer Mapping Software Options
# ---------------------------------------------------------------------------
OVERVIEWER_BIN=$(getDefaultsValue 'mscs-overviewer-bin' $(which overviewer.py))
OVERVIEWER_URL=$(getDefaultsValue 'mscs-overviewer-url' 'http://overviewer.org')
MAPS_LOCATION=$(getDefaultsValue 'mscs-maps-location' $LOCATION'/maps')
MAPS_URL=$(getDefaultsValue 'mscs-maps-url' 'http://minecraft.server.com/maps')

# allow function importing via source command for tests
if printf $0 | grep -qs "runtests\.sh"; then
  # file was sourced, don't execute below here
  return 0
fi

# Respond to the command line arguments.
# ---------------------------------------------------------------------------
# Stores the user-issued command.
COMMAND=$1
if [ "$#" -ge 1 ]; then
  shift 1
fi
case "$COMMAND" in
  start)
    # Grab the latest version information.
    updateVersionsJSON
    # Figure out which worlds to start.
    WORLDS=$(getEnabledWorlds)
    if [ -z "$WORLDS" ]; then
      echo "There are no worlds to start."
      echo "You may want to enable a world:"
      echo "  $PROG enable <world>"
      echo "Or create a new world:"
      echo "  $PROG create <world> <port>"
      echo "Or create the default world at the default port:"
      echo "  $PROG create"
      exit 1
    elif [ "$#" -ge 1 ]; then
      WORLDS=''
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' not recognized.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    fi
    # Start each world requested, if not already running.
    printf "Starting Minecraft Server:"
    for WORLD in $WORLDS; do
      if ! serverRunning $WORLD; then
        printf " $WORLD"
        start $WORLD
      fi
    done
    printf ".\n"
    ;;
  stop | force-stop)
    # Figure out which worlds to stop.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' not recognized.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    # Stop each world requested, if running.
    if [ -z "$WORLDS" ]; then
      printf "Unable to stop worlds: no running worlds found.\n"
      exit 1
    fi
    printf "Stopping Minecraft Server:"
    for WORLD in $WORLDS; do
      # Try to stop the world cleanly.
      if serverRunning $WORLD; then
        printf " $WORLD"
        if [ $(queryNumUsers $WORLD) -gt 0 ]; then
          sendCommand $WORLD "say The server admin has initiated a server shut down."
          sendCommand $WORLD "say The server will shut down in 1 minute..."
          sleep 60
          sendCommand $WORLD "say The server is now shutting down."
        fi
        sendCommand $WORLD "save-all"
        sendCommand $WORLD "save-off"
        if [ "$COMMAND" = "force-stop" ]; then
          forceStop $WORLD
        else
          stop $WORLD
        fi
      elif [ "$COMMAND" = "force-stop" ]; then
        printf " $WORLD"
        forceStop $WORLD
      fi
    done
    printf ".\n"
    ;;
  restart | reload | force-restart | force-reload)
    # Grab the latest version information.
    updateVersionsJSON
    # Figure out which worlds to restart.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' not recognized.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to restart worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Restart each world requested, start those not already
    # running.
    printf "Restarting Minecraft Server:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      if serverRunning $WORLD; then
        if [ $(queryNumUsers $WORLD) -gt 0 ]; then
          sendCommand $WORLD "say The server admin has initiated a server restart."
          sendCommand $WORLD "say The server will restart in 1 minute..."
          sleep 60
          sendCommand $WORLD "say The server is now restarting."
        fi
        sendCommand $WORLD "save-all"
        sendCommand $WORLD "save-off"
        if [ "$(echo \"$COMMAND\" | cut -d '-' -f1)" = "force" ]; then
          forceStop $WORLD
        else
          stop $WORLD
        fi
        sleep 5
      fi
      start $WORLD
    done
    printf ".\n"
    ;;
  create | new)
    if [ -n "$1" ]; then
      if [ -z "$2" ]; then
        printf "A name and port for the new world must be supplied.\n"
        printf "An IP address is optional and usually not needed.\n"
        printf "  Usage: $PROG create <world> <port> [<ip>]\n"
        exit 1
      else
        printf "Creating Minecraft world: $1"
        createWorld "$1" "$2" "$3"
        printf ".\n"
      fi
    elif [ -z "$(getAvailableWorlds)" ]; then
      printf 'Creating default world "%s" at default port %s' \
        $DEFAULT_WORLD $DEFAULT_PORT
      createWorld "$DEFAULT_WORLD" "$DEFAULT_PORT"
      printf ".\n"
    fi
    ;;
  import | copy | cp)
    # Verify the directory argument.
    if [ ! -d "$1" ] || [ ! -r "$1/server.properties" ]; then
      printf "Directory containing a Minecraft world was not provided.\n"
      printf "  Usage: $PROG import <directory> <world> <port> [<ip>]\n"
      exit 1
    fi
    # Verify the name and port arguments.
    if [ -z "$2" ] || [ -z "$3" ] || isWorldAvailable "$2"; then
      printf "An unused name and port for the world must be supplied.\n"
      printf "An IP address is optional and usually not needed.\n"
      printf "  Usage: $PROG import <directory> <world> <port> [<ip>]\n"
      exit 1
    fi
    # Import the world.
    printf "Importing Minecraft world: $2"
    importWorld "$1" "$2" "$3" "$4"
    printf ".\n"
    ;;
  rename)
    # Verify the original world argument.
    if [ -z "$1" ] || ! isWorldAvailable "$1"; then
      printf "A Minecraft world was not provided.\n"
      printf "  Usage: $PROG rename <original world> <new world>\n"
      exit 1
    fi
    # Verify the new world argument.
    if [ -z "$2" ] || isWorldAvailable "$2"; then
      printf "Invalid name for the new world provided.\n"
      printf "  Usage: $PROG rename <original world> <new world>\n"
      exit 1
    fi
    # Make sure the world is stopped.
    if serverRunning "$1"; then
      # If the world server has users logged in, announce that the world is
      # being modified.
      if [ $(queryNumUsers "$1") -gt 0 ]; then
        sendCommand "$1" "say The server admin is modifying this world."
        sendCommand "$1" "say The server will be restarted in 1 minute..."
        sleep 60
        sendCommand "$1" "say The server is now shutting down."
      fi
      # Stop the world server.
      stop "$1"
      sleep 5
    fi
    # Save the port and IP for the world.
    PORT=$(getServerPropertiesValue "$1" "server-port" "$DEFAULT_PORT")
    IP=$(getServerPropertiesValue "$1" "server-ip" "$DEFAULT_IP")
    # Rename the world.
    printf "Renaming Minecraft world: $1"
    mkdir -p "$WORLDS_LOCATION/$2"
    mv $WORLDS_LOCATION/$1 $WORLDS_LOCATION/$2
    if [ -d $WORLDS_LOCATION/$2/$1 ]; then
      mv $WORLDS_LOCATION/$2/$1 $WORLDS_LOCATION/$2/$2
    fi
    createWorld "$2" "$PORT" "$IP"
    printf ".\n"
    ;;
  delete | remove)
    # Get list of enabled worlds.
    if ! isWorldAvailable "$1"; then
      printf "World not found, unable to delete world '$1'.\n"
      exit 1
    fi
    printf "Deleting Minecraft world: $1"
    if serverRunning "$1"; then
      # If the world server has users logged in, announce that the world is
      # being deleted.
      if [ $(queryNumUsers "$1") -gt 0 ]; then
        sendCommand "$1" "say The server admin is deleting this world."
        sendCommand "$1" "say The server will be deleted in 1 minute..."
        sleep 60
        sendCommand "$1" "say The server is now shutting down."
      fi
      # Stop the world server.
      stop "$1"
      sleep 5
    fi
    # Delete the world.
    deleteWorld "$1"
    printf ".\n"
    ;;
  disable)
    # Get list of enabled worlds.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        elif isWorldDisabled "$arg"; then
          printf "Unable to disable already disabled world '$arg'.\n"
          exit 1
        else
          printf "World not found, unable to disable world '$arg'.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to disable worlds: no enabled worlds found.\n"
      exit 1
    fi
    printf "Disabling Minecraft world:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      if serverRunning "$WORLD"; then
        # If the world server has users logged in, announce that the world is
        # being disabled.
        if [ $(queryNumUsers "$WORLD") -gt 0 ]; then
          sendCommand "$WORLD" "say The server admin is disabling this world."
          sendCommand "$WORLD" "say The server will be disabled in 1 minute..."
          sleep 60
          sendCommand "$WORLD" "say The server is now shutting down."
        fi
        # Stop the world server.
        stop "$WORLD"
        sleep 5
      fi
      # Disable the world.
      disableWorld "$WORLD"
    done
    printf ".\n"
    ;;
  enable)
    # Grab the latest version information.
    updateVersionsJSON
    # Get list of disabled worlds.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldDisabled "$arg"; then
          WORLDS="$WORLDS $arg"
        elif isWorldEnabled "$arg"; then
          printf "Unable to enable already enabled world '$arg'.\n"
          exit 1
        else
          printf "World not found, unable to enable world '$arg'.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getDisabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to enable worlds: no disabled worlds found.\n"
      exit 1
    fi
    printf "Enabling Minecraft world:"
    # Enable the world(s).
    for WORLD in $WORLDS; do
      printf " $WORLD"
      # Enable the world.
      enableWorld "$WORLD"
      # Start the world.
      start "$WORLD"
    done
    printf ".\n"
    ;;
  ls | list)
    # Grab the desired list of worlds.
    WORLDS=""
    case "$1" in
      enabled)
        WORLDS=$(getEnabledWorlds)
        ;;
      disabled)
        WORLDS=$(getDisabledWorlds)
        ;;
      running)
        for WORLD in $(getEnabledWorlds); do
          if serverRunning $WORLD; then
            WORLDS="$WORLDS $WORLD"
          fi
        done
        ;;
      stopped)
        for WORLD in $(getEnabledWorlds); do
          if ! serverRunning $WORLD; then
            WORLDS="$WORLDS $WORLD"
          fi
        done
        ;;
      "")
        WORLDS=$(getAvailableWorlds)
        ;;
      *)
        echo "Unknown list option: $1."
        echo "  Try '$PROG help' for help."
        exit 1
        ;;
    esac
    case "$COMMAND" in
      ls)
        # Simple list
        for WORLD in $WORLDS; do
          WPORT=$(getServerPropertiesValue "$WORLD" server-port "")
          printf "  $WORLD: $WPORT"
          if isWorldEnabled "$WORLD"; then
            printf '\n'
          else
            printf ' (disabled)\n'
          fi
        done
        ;;
      list)
        # Detailed list
        for WORLD in $WORLDS; do
          printf "  $WORLD:"
          if isWorldEnabled "$WORLD"; then
            printf '\n'
          else
            printf ' (disabled)\n'
          fi
          for PROP in $DETAILED_LISTING_PROPERTIES; do
            printf "    $PROP="
            getServerPropertiesValue "$WORLD" "$PROP" ""
          done
          printf '\n'
        done
        ;;
    esac
    ;;
  status | show | status-json | show-json)
    # Figure out which worlds to show the status for.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldAvailable "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' not recognized.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getAvailableWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to get world status: no available worlds found.\n"
      exit 1
    fi
    case "$COMMAND" in
      status-json | show-json)
        # Show the status of each world requested in JSON format.
        JSON=""
        for WORLD in $WORLDS; do
          if [ "$JSON" ]; then
            JSON="$JSON, "
          fi
          JSON="$JSON\"$WORLD\":$(worldStatusJSON $WORLD)"
        done
        printf "{%s}" "$JSON"
        ;;
      *)
        # Show the status of each world requested.
        printf "Minecraft Server Status:\n"
        for WORLD in $WORLDS; do
          printf "  $WORLD: "
          worldStatus $WORLD
        done
        ;;
    esac
    ;;
  sync | synchronize)
    # Figure out which worlds to synchronize.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' not recognized.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to sync worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Synchronize the images for each world.
    printf "Synchronizing Minecraft Server:"
    for WORLD in $WORLDS; do
      if serverRunning $WORLD; then
        printf " $WORLD"
        sendCommand $WORLD "save-all"
        if [ $ENABLE_MIRROR -eq 1 ]; then
          sendCommand $WORLD "save-off"
          sleep 20
          syncMirrorImage $WORLD
          sendCommand $WORLD "save-on"
        fi
      fi
    done
    printf ".\n"
    ;;
  broadcast)
    # Get list of enabled worlds.
    WORLDS=$(getEnabledWorlds)
    if [ -z "$WORLDS" ]; then
      printf "Unable to broadcast: no enabled worlds found.\n"
      exit 1
    fi
    if [ -n "$1" ]; then
      # Broadcast the message to all of the enabled worlds.
      printf "Broadcasting command to world:"
      for WORLD in $WORLDS; do
        if serverRunning $WORLD; then
          printf " $WORLD"
          sendCommand $WORLD "$*"
        fi
      done
      printf ".\n"
    else
      printf "Usage:  $PROG $COMMAND <command>\n"
      printf "   ie:  $PROG $COMMAND say Hello World!\n"
      exit 1
    fi
    ;;
  send)
    # Check for the world command line argument.
    if isWorldEnabled "$1" && [ -n "$2" ]; then
      WORLD=$1
      shift 1
      printf "Sending command to world: $WORLD - '$*'.\n"
      sendCommand $WORLD "$*"
    else
      printf "Minecraft world '$1' not enabled or not found!\n"
      printf "Usage:  $PROG $COMMAND <world> <command>\n"
      printf "   ie:  $PROG $COMMAND world say Hello World!\n"
      exit 1
    fi
    ;;
  console)
    # Check for the world command line argument.
    if isWorldEnabled "$1"; then
      printf "Connecting to server console: $1.\n"
      printf "  Hit <Ctrl-D> to detach.\n"
      sleep 3
      serverConsole $1
    else
      if [ -n "$1" ]; then
        printf "Minecraft world '$1' not enabled or not found!\n"
      else
        printf "Minecraft world not provided!\n"
      fi
      printf "  Usage:  $PROG $COMMAND <world>\n"
      exit 1
    fi
    ;;
  watch)
    # Check for the world command line argument.
    if isWorldEnabled "$1"; then
      printf "Monitoring Minecraft Server: $1.\n"
      watchLog $1
    else
      if [ -n "$1" ]; then
        printf "Minecraft world '$1' not enabled or not found!\n"
      else
        printf "Minecraft world not provided!\n"
      fi
      printf "  Usage:  $PROG $COMMAND <world>\n"
      exit 1
    fi
    ;;
  logrotate)
    # Figure out which worlds to rotate the log.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' does not exist or not enabled.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to logrotate worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Rotate the log for each world requested.
    printf "Rotating Minecraft Server Log:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      rotateLog $WORLD
    done
    printf ".\n"
    ;;
  backup)
    # Figure out which worlds to backup.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' does not exist or not enabled.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to backup worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Backup each world requested.
    printf "Backing up Minecraft Server:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      # Create a lock file so that we don't create duplicate processes.
      if $(createLockFile $WORLD "backup"); then
        if serverRunning $WORLD; then
          sendCommand $WORLD "say Backing up the world."
          sendCommand $WORLD "save-all"
          sendCommand $WORLD "save-off"
          sleep 20
          worldBackup $WORLD
          sendCommand $WORLD "save-on"
          sendCommand $WORLD "say Backup complete."
        else
          worldBackup $WORLD
        fi
        # Remove the lock file.
        removeLockFile $WORLD "backup"
      else
        printf "\nError lock file for world $WORLD could not be created."
        printf "  Is the world already running a backup?\n"
      fi
    done
    printf ".\n"
    ;;
  list-backups)
    if isWorldEnabled "$1"; then
      worldBackupList "$1"
    elif [ -n "$1" ]; then
      printf "World '$1' does not exist or not enabled.\n"
      printf "  Usage:  $PROG $COMMAND <world>\n"
      exit 1
    else
      printf "World not supplied.\n"
      printf "  Usage:  $PROG $COMMAND <world>\n"
      exit 1
    fi
    ;;
  restore-backup)
    if [ -z $1 ]; then
      printf "World not supplied.\n"
      printf "  Usage:  $PROG $COMMAND <world> <datetime>\n"
      exit 1
    elif ! isWorldAvailable "$1"; then
      printf "World '$1' not recognized.\n"
      printf "  Usage:  $PROG $COMMAND <world> <datetime>\n"
      exit 1
    elif serverRunning "$1"; then
      printf "World '$1' is running. Stop it first\n"
      printf "  $PROG stop $1\n"
      exit 1
    elif worldBackup "$1"; then
      worldBackupRestore "$1" "$2"
    else
      echo "Current world's state backup failed. Restore canceled."
      exit 1
    fi
    ;;
  update | force-update)
    # Handle the force option.
    if [ "$COMMAND" = "force-update" ]; then
      if [ -s $VERSIONS_JSON ]; then
        # Make a backup copy of the version_manifest.json file.
        cp -fp "$VERSIONS_JSON" "$VERSIONS_JSON.bak"
        printf "Removing cached version manifest.\n"
      fi
      rm -f $VERSIONS_JSON
    fi
    # Grab the latest version information.
    updateVersionsJSON
    # Figure out which worlds to update.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' does not exist or not enabled.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to update worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Stop all of the world servers and backup the worlds.
    RUNNING=
    printf "Stopping Minecraft Server:"
    for WORLD in $WORLDS; do
      if serverRunning $WORLD; then
        RUNNING="$RUNNING $WORLD"
        printf " $WORLD"
        if [ $(queryNumUsers $WORLD) -gt 0 ]; then
          sendCommand $WORLD "say The server admin has initiated a software update."
          sendCommand $WORLD "say The server will restart and update in 1 minute..."
          sleep 60
          sendCommand $WORLD "say The server is now restarting."
        fi
        sendCommand $WORLD "save-all"
        sendCommand $WORLD "save-off"
        stop $WORLD
      fi
    done
    printf ".\n"
    printf "Backing up Minecraft Server:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      worldBackup $WORLD
    done
    printf ".\n"
    # Handle the force option.
    if [ "$COMMAND" = "force-update" ]; then
      printf "Removing Minecraft Server software:"
      for WORLD in $WORLDS; do
        printf " $WORLD"
        rm -f $(getServerLocation "$WORLD")/$(getServerJar "$WORLD")
      done
      printf ".\n"
    fi
    # Update the server software.
    printf "Updating Server Software:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      updateServerSoftware "$WORLD"
    done
    printf ".\n"
    printf "Restarting Minecraft Server:"
    for WORLD in $RUNNING; do
      printf " $WORLD"
      start $WORLD
    done
    printf ".\n"
    ;;
  map | overviewer)
    # Grab the latest version information.
    updateVersionsJSON
    # Make sure that the Minecraft Overviewer software exists.
    if [ ! -e "$OVERVIEWER_BIN" ]; then
      printf "Minecraft Overviewer software not found.\n"
      exit 1
    fi
    # Figure out which worlds to map.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' does not exist or not enabled.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to map worlds: no enabled worlds found.\n"
      exit 1
    fi
    # Run Minecraft Overviewer on each world requested.
    printf "Running Minecraft Overviewer mapping:"
    for WORLD in $WORLDS; do
      printf " $WORLD"
      # Create a lock file so that we don't create duplicate processes.
      if $(createLockFile $WORLD "overviewer"); then
        overviewer "$WORLD"
        # Remove the lock file.
        removeLockFile $WORLD "overviewer"
      else
        printf "\nError lock file for world $WORLD could not be created."
        printf "  Is the world already running Overviewer?\n"
      fi
    done
    printf ".\n"
    ;;
  query | query-raw | query-json)
    # Figure out which worlds to show the status for.
    if [ "$#" -ge 1 ]; then
      for arg in "$@"; do
        if isWorldEnabled "$arg"; then
          WORLDS="$WORLDS $arg"
        else
          printf "World '$arg' does not exist or not enabled.\n"
          printf "  Usage:  $PROG $COMMAND <world1> <world2> <...>\n"
          exit 1
        fi
      done
    else
      WORLDS=$(getEnabledWorlds)
    fi
    if [ -z "$WORLDS" ]; then
      printf "Unable to query worlds: no enabled worlds found.\n"
      exit 1
    fi
    case "$COMMAND" in
      query | query-raw)
        for WORLD in $WORLDS; do
          queryDetailedStatus "$WORLD"
          printf "\n"
        done
        ;;
      query-json)
        for WORLD in $WORLDS; do
          queryDetailedStatusJSON "$WORLD"
          printf "\n"
        done
        ;;
    esac
    ;;
  usage | help)
    printf "Minecraft Server Control Script\n"
    printf "\n"
    usage
    ;;
  *)
    printf "Error in command line usage.\n"
    printf "\n"
    usage
    exit 1
    ;;
esac
exit 0