#!/bin/bash

echo "Downloading db2-orchestrator ..."
if [[ $EUID -eq 0 ]]; then
   curl -L -s https://github.com/vikramkhatri/db2/releases/download/1.0/db2-orchestrator -o /usr/bin
   chmod +x /usr/bin/db2-orchestrator
   echo "You can run db2-orchestrator now"
else
   curl -L -s https://github.com/vikramkhatri/db2/releases/download/1.0/db2-orchestrator -o .
   chmod +x ./db2-orchestrator
   echo "You can run ./db2-orchestrator now"
fi

echo "Download complete."

