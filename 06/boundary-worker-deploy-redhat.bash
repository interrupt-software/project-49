sudo apt-get update
sudo apt-get install zip -y

wget https://releases.hashicorp.com/boundary/0.6.2/boundary_0.6.2_linux_amd64.zip
unzip boundary_0.6.2_linux_amd64.zip

sudo useradd --system --home /etc/boundary.d --shell /bin/false boundary

sudo chown root:root boundary
sudo mv boundary /usr/local/bin/.
/usr/local/bin/boundary config autocomplete install

VAULT_ADDR=https://vault.interrupt-software.ca:8200
VAULT_TOKEN=$(vault token create -policy=boundary-kms-transit)
WORKER_ADDR=$(sudo ifconfig eth0 | awk -F ' *|:' '/inet /{print $3}')

cat << EOF > boundary-worker.hcl
listener "tcp" {
  purpose = "proxy"
  address = "127.0.0.1"
  tls_disable = "true"
}

worker {
  # Name attr must be unique across workers
  name = "demo-worker-1"
  description = "A default worker created demonstration"

  # Workers must be able to reach controllers on :9201
  controllers = [
    "$CONTROLLER_ADDR"
  ]

  public_addr = "$WORKER_ADDR"

  tags {
    type   = ["prod", "webservers"]
    region = ["us-east-1"]
  }
}

kms "transit" {
  purpose = "worker-auth"
  address = "$VAULT_ADDR"
  token   = "$VAULT_TOKEN"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "boundary-worker-auth"
  mount_path         = "transit/"
  namespace          = "root/"

  // TLS Configuration
  tls_skip_verify    = "true"
}
EOF

sudo mkdir --parents /etc/boundary.d
sudo mv boundary-worker.hcl /etc/boundary.d
sudo chown --recursive boundary:boundary /etc/boundary.d

sudo cat << EOF > boundary-worker.service
[Unit]
Description=boundary worker

[Service]
ExecStart=/usr/local/bin/boundary server -config /etc/boundary.d/boundary-worker.hcl
User=boundary
Group=boundary
LimitMEMLOCK=infinity
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root boundary-worker.service
sudo mv boundary-worker.service /etc/systemd/system
sudo chmod 664 /etc/systemd/system/boundary-worker.service

sudo systemctl daemon-reload
sudo systemctl enable boundary-worker
sudo systemctl start boundary-worker
sudo systemctl status boundary-worker


# For troubleshooting 
# sudo systemctl restart boundary-worker; sudo tail -f /var/log/messages 