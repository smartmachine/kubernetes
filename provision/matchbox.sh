#!/usr/bin/env bash
echo "Configuring matchbox certificates"
mv /home/core/matchbox/certs /etc/matchbox
echo "Provisioning matchbox"
mkdir -p /var/lib/matchbox/assets
mv -i /home/core/matchbox/* /var/lib/matchbox
rm -rf /home/core/matchbox
COREOS_VERSION=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//g')
echo "CoreOS Version: ${COREOS_VERSION}"
sed -i "s/@COREOS_VERSION@/${COREOS_VERSION}/g" /var/lib/matchbox/ignition/linux-install.yaml.tmpl
sed -i "s/@COREOS_VERSION@/${COREOS_VERSION}/g" /var/lib/matchbox/profiles/linux-install.json
echo "Downloading coreos distribution"
cd /var/lib/matchbox/assets
/tmp/get-coreos alpha ${COREOS_VERSION} .
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
