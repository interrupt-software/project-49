sudo apt-get update
sudo apt-get install zip -y

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-12 postgresql-client-12
sudo apt-get -y install postgresql-12 postgresql-client-12
 
sudo useradd --system --home /etc/boundary.d --shell /bin/false boundary

sudo -u postgres bash -c "psql -c \"CREATE DATABASE boundary; \""
sudo -u postgres bash -c "psql -c \"CREATE USER boundary WITH PASSWORD 'boundarydemo'; \"" boundary
sudo -u postgres bash -c "psql -c \"ALTER USER boundary WITH SUPERUSER; \""

VAULT_ADDR=https://vault.interrupt-software.ca:8200

vault secrets enable transit
vault write -f transit/keys/boundary-root
vault write -f transit/keys/boundary-worker-auth
vault write -f transit/keys/boundary-recovery
vault policy write boundary-kms-transit boundary-kms-transit.hcl

wget https://releases.hashicorp.com/boundary/0.6.2/boundary_0.6.2_linux_amd64.zip
unzip boundary_0.6.2_linux_amd64.zip

sudo chown root:root boundary
sudo mv boundary /usr/local/bin/.
/usr/local/bin/boundary config autocomplete install

VAULT_TOKEN=$(vault token create -policy=boundary-kms-transit)
CONTROLLER_ADDR=$(sudo ifconfig eth0 | awk -F ' *|:' '/inet /{print $3}')

cat << EOF > boundary-controller.hcl
# Disable memory lock: https://www.man7.org/linux/man-pages/man2/mlock.2.html
disable_mlock = true

# Controller configuration block
controller {
  # This name attr must be unique across all controller instances if running in HA mode
  name = "demo-controller-1"
  description = "A controller for a demo!"

  # Database URL for postgres. This can be a direct "postgres://"
  # URL, or it can be "file://" to read the contents of a file to
  # supply the url, or "env://" to name an environment variable
  # that contains the URL.
  database {
      url = "postgresql://boundary:boundarydemo@localhost:5432/boundary"
  }
}

# API listener configuration block
listener "tcp" {
  address = "0.0.0.0"
  purpose = "api"

  tls_disable = "true"
}

# Data-plane listener configuration block (used for worker coordination)
listener "tcp" {
  address = "$CONTROLLER_ADDR"
  purpose = "cluster"
}

# Root KMS configuration block: this is the root key for Boundary
# Use a production KMS such as AWS KMS in production installs
kms "transit" {
  purpose = "root"
  address = "$VAULT_ADDR"
  token   = "$VAULT_TOKEN"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "boundary-root"
  mount_path         = "transit/"
  namespace          = "root/"

  // TLS Configuration
  tls_skip_verify    = "true"
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
sudo mv boundary-controller.hcl /etc/boundary.d
sudo chown --recursive boundary:boundary /etc/boundary.d

sudo cat << EOF > boundary-controler.service
[Unit]
Description=boundary controller

[Service]
ExecStart=/usr/local/bin/boundary server -config /etc/boundary.d/boundary-controller.hcl
User=boundary
Group=boundary
LimitMEMLOCK=infinity
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK

[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root boundary-controler.service
sudo mv boundary-controler.service /etc/systemd/system
sudo chmod 664 /etc/systemd/system/boundary-controler.service

ln -s /etc/systemd/system/boundary-controller.service /etc/systemd/system/boundary-controller.service

sudo systemctl daemon-reload
sudo systemctl enable boundary-controler
sudo systemctl start boundary-controler

sudo /usr/local/bin/boundary database init -config /etc/boundary.d/boundary-controller.hcl 

# For troubleshooting 
# sudo systemctl restart boundary-controler; sudo tail -f /var/log/syslog 
