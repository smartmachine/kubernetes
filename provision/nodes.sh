#!/usr/bin/env bash
echo "Installing Kubernetes auth config"
cp /home/core/bootkube/auth/kubeconfig /etc/kubernetes/kubeconfig
echo "Installing etcd auth config"
mkdir -p /etc/ssl/etcd
cp /home/core/bootkube/tls/etcd-* /etc/ssl/etcd/
chown -R etcd:etcd /etc/ssl/etcd
chmod -R 500 /etc/ssl/etcd
if [ -d /opt/bootkube ] ; then
  echo "Running on master node."
  echo "  - Copying bootkube assets into place"
  mv /home/core/bootkube /opt/bootkube/assets
  echo "  - Starting bootkube ... this may take a few minutes"
  nohup systemctl start bootkube 2>&1 >/dev/null &
  echo "  - Done."
else
  echo "Running on worker node, deleting bootkube assets"
  rm -rf /home/core/bootkube
fi
