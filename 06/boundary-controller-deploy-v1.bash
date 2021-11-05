
#  This guide is specific to RedHat 8 on AWS
# jq is utility to handle JSON objects. 
# We use it to extract keys

sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo update -y
sudo yum install jq -y

##### end of jq


#### Use Postgres 11 with Boundary.

sudo yum -y remove postgresql
sudo yum -y remove postgres\*
sudo rm -fR rm /var/lib/pgsql
sudo userdel -r postgres

sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf clean all
sudo dnf -y install postgresql11-server postgresql11
sudo dnf info postgresql11-server postgresql11
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
sudo systemctl enable --now postgresql-11

sudo dnf -y install postgresql11-contrib
sudo systemctl restart postgresql-11
sudo systemctl status postgresql-11

### If you have firewall enabled, allow Postgres to connect

sudo firewall-cmd --add-service=postgresql --permanent
sudo firewall-cmd --reload

#### End of Firewall


#### Allow service connections using passwords. 
#### These are not the only options. 

sudo vim /var/lib/pgsql/11/data/pg_hba.conf

####

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5

####


sudo systemctl restart postgresql-11
sudo systemctl status postgresql-11

#### If all is working, proceed to generate Boundary assets

sudo -u postgres bash -c "psql -c \"CREATE DATABASE boundary; \""
sudo -u postgres bash -c "psql -c \"CREATE USER boundary WITH PASSWORD 'boundarydemo'; \""
sudo -u postgres bash -c "psql -c \"ALTER USER boundary WITH SUPERUSER; \""

#### Test the boundary user
psql -U boundary -h localhost -p 5432 boundary -W

sudo useradd --system --home /etc/boundary.d --shell /bin/false boundary

# Prepare work on Vault

export VAULT_TOKEN=admin.token.for.setup
VAULT_ADDR=https://vault.interrupt-software.ca:8200

# We will replace the VAULT_TOKEN later

vault secrets enable transit
vault write -f transit/keys/boundary-root
vault write -f transit/keys/boundary-worker-auth
vault write -f transit/keys/boundary-recovery
vault policy write boundary-kms-transit boundary-kms-transit.hcl

wget https://releases.hashicorp.com/boundary/0.6.2/boundary_0.6.2_linux_amd64.zip
# or
# curl --remote-name https://releases.hashicorp.com/boundary/0.6.2/boundary_0.6.2_linux_amd64.zip

unzip boundary_0.6.2_linux_amd64.zip

sudo chown root:root boundary
sudo mv boundary /usr/local/bin/.
/usr/local/bin/boundary config autocomplete install
complete -C /usr/local/bin/boundary boundary

# Set a unique token for the Boundary KMS exchange
VAULT_TOKEN=$(vault token create -policy=boundary-kms-transit -format=json | jq -r '.auth.client_token')

# Test this variable. If it does not produce the internal
# IP on eth0, then just set it manually.
CONTROLLER_ADDR=$(ip addr show eth0 | awk -F ' *|:' '/inet /{print $3}' | cut -d / -f 1)

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

sudo cat << EOF > boundary-controller.service
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

sudo chown root:root boundary-controller.service
sudo mv boundary-controller.service /usr/lib/systemd/system/
sudo chmod 644 /usr/lib/systemd/system/boundary-controller.service
sudo ln -s /usr/lib/systemd/system/boundary-controller.service /etc/systemd/system/boundary-controller.service

sudo getenforce
sudo setenforce 0
sudo getenforce
# Permissive

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable boundary-controller

# We need to run the setup before starting the Boundary service

sudo /usr/local/bin/boundary database init -config /etc/boundary.d/boundary-controller.hcl 
sudo systemctl start boundary-controller
sudo systemctl status boundary-controller


# If Boundary is not starting, use the following to see the logs
# sudo systemctl restart boundary-controller; sudo tail -f /var/log/messages 