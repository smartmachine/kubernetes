#!/bin/bash
if [ -z ${1+x} ]; then echo -e "Give a server name to tail:\n # bin/tail.sh matchbox" ; exit 1 ; fi
vagrant ssh $1 -c "journalctl -f"
