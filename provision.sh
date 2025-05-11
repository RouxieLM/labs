echo "Updating VM..."
apt-get update -y && apt-get upgrade -y
echo "Done !"

echo "Installing default tools"
apt-get install curl wget vim net-tools -y
echo "Done !"

if ! hostname | grep "loadbalancer"; then
  echo "Setting up kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  echo "Done !"

  echo "Adding alias 'k' for 'kubectl'"
  echo "alias k='kubectl'" >> /home/vagrant/.bashrc
  chown vagrant:vagrant /home/vagrant/.bashrc

  echo "Adding auto-completion for 'kubectl' and 'k' commands"
  echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
  echo "complete -F __start_kubectl k" >> /home/vagrant/.bashrc
  echo "Done !"
fi

if hostname | grep -q "master-1"; then
  su - vagrant -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ""'

  cp /home/vagrant/.ssh/id_rsa.pub /vagrant/master1.pub
  chown vagrant:vagrant /vagrant/master1.pub
fi

if [ -f /vagrant/master1.pub ]; then
  mkdir -p /home/vagrant/.ssh
  cat /vagrant/master1.pub >> /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
  chmod 600 /home/vagrant/.ssh/authorized_keys
fi

echo "[INFO] Updating /etc/hosts for cluster node resolution"

cat <<EOF >> /etc/hosts
192.168.56.11 m1
192.168.56.12 m2
192.168.56.13 m3
192.168.56.21 w1
192.168.56.22 w2
192.168.56.23 w3
192.168.56.30 lb
EOF