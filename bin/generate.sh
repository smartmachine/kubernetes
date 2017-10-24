#!/usr/bin/env bash

set -e
set -o pipefail

echo "Determining operating system"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  BINPATH=bin/linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
  BINPATH=bin/darwin
else
  echo "Your operating system is not currently supported.  Please use MacOS or Linux."
  exit 1
fi

echo "Rendering bootkube configurations"
rm -rf config/bootkube
${BINPATH}/bootkube render --asset-dir config/bootkube --api-servers https://cluster.kube.com:443 --api-server-alt-names=DNS=cluster.kube.com --etcd-servers https://master-1.kube.com:2379 --pod-cidr 10.2.0.0/16 --service-cidr 10.3.0.0/16 --network-provider experimental-calico

echo "Creating matchbox certificates"
export SAN=DNS.1:matchbox.kube.com,IP.1:192.168.99.2

rm -rf config/matchbox/certs
mkdir -p config/matchbox/certs
cd config/matchbox/certs

if [ -z $SAN ]
  then echo "Set SAN with a DNS or IP for matchbox (e.g. export SAN=DNS.1:matchbox.example.com,IP.1:192.168.1.42)."
  exit 1
fi

echo "Creating self signed CA, server cert/key, and client cert/key..."

# basic files/directories
mkdir -p {certs,crl,newcerts}
touch index.txt
echo 1000 > serial

# CA private key (unencrypted)
openssl genrsa -out ca.key 4096
# Certificate Authority (self-signed certificate)
openssl req -config ../../openssl.conf -new -x509 -days 3650 -sha256 -key ca.key -extensions v3_ca -out ca.crt -subj "/CN=fake-ca"

# End-entity certificates

# Server private key (unencrypted)
openssl genrsa -out server.key 2048
# Server certificate signing request (CSR)
openssl req -config ../../openssl.conf -new -sha256 -key server.key -out server.csr -subj "/CN=fake-server"
# Certificate Authority signs CSR to grant a certificate
openssl ca -batch -config ../../openssl.conf -extensions server_cert -days 365 -notext -md sha256 -in server.csr -out server.crt -cert ca.crt -keyfile ca.key

# Client private key (unencrypted)
openssl genrsa -out client.key 2048
# Signed client certificate signing request (CSR)
openssl req -config ../../openssl.conf -new -sha256 -key client.key -out client.csr -subj "/CN=fake-client"
# Certificate Authority signs CSR to grant a certificate
openssl ca -batch -config ../../openssl.conf -extensions usr_cert -days 365 -notext -md sha256 -in client.csr -out client.crt -cert ca.crt -keyfile ca.key

# Remove CSR's
rm -rf *.csr certs crl index* newcerts serial*

echo "Transpiling Container Linux Config to ignition JSON"
cd ../../..
${BINPATH}/ct -strict -platform vagrant-virtualbox < config/ignition/ignition.yaml > config/ignition/ignition.json
