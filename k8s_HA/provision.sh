log() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

ok() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [OK]   $1"
}

error() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

log "Updating and upgrading system packages..."
if apt-get update -y && apt-get upgrade -y; then
  ok "System updated successfully."
else
  error "System update failed."
fi

log "Installing default tools: curl, wget, vim, net-tools..."
if apt-get install curl wget vim net-tools htop -y; then
  ok "Default tools installed."
else
  error "Tool installation failed."
fi

if ! hostname | grep -q "loadbalancer"; then
  log "Setting up kubectl..."

  if curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
     install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&
     rm kubectl; then
    ok "kubectl installed."
  else
    error "kubectl installation failed."
  fi

  log "Adding alias 'k' for 'kubectl' in .bashrc"
  echo "alias k='kubectl'" >> /home/vagrant/.bashrc
  chown vagrant:vagrant /home/vagrant/.bashrc

  log "Enabling autocompletion for 'kubectl' and 'k'"
  echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
  echo "complete -F __start_kubectl k" >> /home/vagrant/.bashrc
  ok "Alias and autocompletion configured."
fi

if hostname | grep -q "master-1"; then
  log "Generating SSH key for vagrant user on master-1..."
  if su - vagrant -c 'ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ""'; then
    ok "SSH key generated."

    cp /home/vagrant/.ssh/id_rsa.pub /vagrant/master1.pub
    chown vagrant:vagrant /vagrant/master1.pub
    ok "Public key copied to /vagrant/master1.pub"
  else
    error "SSH key generation failed."
  fi
fi

if [ -f /vagrant/master1.pub ]; then
  log "Adding master-1 public key to authorized_keys..."
  mkdir -p /home/vagrant/.ssh
  cat /vagrant/master1.pub >> /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
  chmod 600 /home/vagrant/.ssh/authorized_keys
  ok "Public key added to authorized_keys."
fi

log "Updating /etc/hosts for cluster node resolution..."
cat <<EOF >> /etc/hosts
192.168.56.11 m1 master-1
192.168.56.12 m2 master-2
192.168.56.13 m3 master-3
192.168.56.21 w1 worker-1
192.168.56.22 w2 worker-2
192.168.56.23 w3 worker-3
192.168.56.30 lb loadbalancer
EOF
ok "/etc/hosts updated."