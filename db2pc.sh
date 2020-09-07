#!/bin/bash

echo "Downloading db2-orchestrator ..."
if [[ $EUID -eq 0 ]]; then
   curl -L -s https://github.com/vikramkhatri/db2/releases/download/1.0/db2-orchestrator -o /usr/local/bin/db2-orchestrator
   chmod +x /usr/local/bin/db2-orchestrator
   echo "Installed /usr/local/bin/db2-orchestrator"
   ls -l /usr/local/bin/db2-orchestrator
else
   curl -L -s https://github.com/vikramkhatri/db2/releases/download/1.0/db2-orchestrator -o ./db2-orchestrator
   chmod +x ./db2-orchestrator
   echo "Installed $HOME/db2-orchestrator"
fi

echo "Download complete."

