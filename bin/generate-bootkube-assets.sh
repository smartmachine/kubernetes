#!/usr/bin/env bash
rm -rf config/assets
./bin/bootkube render --asset-dir config/assets --api-servers https://cluster.kube.com:443 --api-server-alt-names=DNS=cluster.kube.com --etcd-servers https://master-1.kube.com:2379 --pod-cidr 10.2.0.0/16 --service-cidr 10.3.0.0/16 --experimental-calico-network-policy
