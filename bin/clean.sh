#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  BINPATH=bin/linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
  BINPATH=bin/darwin
else
  echo "Your operating system is not currently supported.  Please use MacOS or Linux."
  exit 1
fi

echo "Removing all generated artifacts ...."
rm -rf config/bootkube
rm -rf config/matchbox/certs
rm -rf config/user-data
