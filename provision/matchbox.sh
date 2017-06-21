#!/usr/bin/env bash
echo "Moving Cloud Config data into place"
mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
echo "Configuring matchbox certificates"
mv /home/core/matchbox/certs /etc/matchbox
echo "Provisioning matchbox"
mkdir -p /var/lib/matchbox/assets
mv -i /home/core/matchbox/* /var/lib/matchbox
rm -rf /home/core/matchbox
echo "Downloading coreos distribution"
cd /var/lib/matchbox/assets
/tmp/get-coreos stable $(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//g') .
rm -rf /tmp/get-coreos
echo "Installing matchbox service"
mv /tmp/matchbox.service /etc/systemd/system
systemctl daemon-reload
systemctl enable matchbox
systemctl start matchbox
echo "Installing dnsmasq service"
mv /tmp/dnsmasq.service /etc/systemd/system
systemctl daemon-reload
systemctl enable dnsmasq
systemctl start dnsmasq
