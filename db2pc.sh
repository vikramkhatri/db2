#!/bin/bash

TOOL=db2-orchestrator

# Determine the latest version by version number.
if [ "x${DB2PC_VERSION}" = "x" ] ; then
  DB2PC_VERSION=$(curl -sL https://api.github.com/repos/vikramkhatri/db2/releases/latest | \
                  grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  DB2PC_VERSION="${DB2PC_VERSION##*/}"
fi


if [ "x${DB2PC_VERSION}" = "x" ] ; then
  printf "Unable to get latest db2pc version. Set DB2PC_VERSION env var and re-run. For example: export DB2PC_VERSION=1.0.1"
  exit;
fi

URL="https://github.com/vikramkhatri/db2/releases/download/$DB2PC_VERSION/$TOOL"
printf "\nDownloading %s from %s ..." "$DB2PC_VERSION" "$URL"
if [[ $EUID -eq 0 ]]; then
   curl -L -s $URL -o /usr/local/bin/$TOOL
   chmod +x /usr/local/bin/$TOOL
   echo "Installed $TOOL in /usr/local/bin/$TOOL"
   ls -l /usr/local/bin/$TOOL
else
   curl -L -s $URL -o ./$TOOL
   chmod +x ./$TOOL
   echo "Installed in $HOME/$TOOL"
fi


echo "To use tool $TOOL, run"
echo "$TOOL init               -- To create the initial yaml file that you can modify with your cluster information"
echo "$TOOL generate all       -- To generate all scripts [Optional]"
echo "$TOOL install all        -- To deploy all components"
echo
echo "$TOOL install linbit     -- To deploy linbit storage"
echo "$TOOL install pacemaker  -- To deploy pacemaker"
echo "$TOOL install db2        -- To deploy db2"
echo
echo "$TOOL cleanup linbit     -- To cleanup linbit storage"
echo "$TOOL cleanup pacemaker  -- To cleanup pacemaker"
echo "$TOOL cleanup db2        -- To cleanup db2"



