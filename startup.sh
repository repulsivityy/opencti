echo "####################"
echo "Uninstalling Docker"
echo "####################"
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

echo "####################"
echo "Updating OS"
echo "####################"
sudo apt-get update && sudo apt-get upgrade -y

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER

echo "####################"
echo "Getting Environment Ready"
echo "####################"

mkdir ~/opencti
cd ~/opencti

echo "vm.max_map_count=1048575" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=1048575

echo ""
echo "####################"
echo "Configure OpenCTI"
echo "####################"

TTY="/dev/tty"
[ ! -e /dev/tty ] && TTY="/dev/stdin"

read -p "Enter OpenCTI Admin Email: " OPENCTI_ADMIN_EMAIL < "$TTY"
read -s -p "Enter OpenCTI Admin Password: " OPENCTI_ADMIN_PASSWORD < "$TTY"
echo ""
read -p "Enter Open-AppSec Token (press Enter to skip): " OPEN_APPSEC_TOKEN < "$TTY"
read -p "Enter VirusTotal / GTI API Key (press Enter to skip): " GTI_API_KEY < "$TTY"
read -p "Enter URLScan API Key (press Enter to skip): " URLSCAN_API_KEY < "$TTY"
read -p "Enter AlienVault API Key (press Enter to skip): " ALIENVAULT_API_KEY < "$TTY"
read -p "Enter GreyNoise API Key (press Enter to skip): " GREYNOISE_API_KEY < "$TTY"

(cat << EOF
OPENCTI_ADMIN_EMAIL=${OPENCTI_ADMIN_EMAIL}
OPENCTI_ADMIN_PASSWORD=${OPENCTI_ADMIN_PASSWORD}
OPENCTI_ADMIN_TOKEN=$(cat /proc/sys/kernel/random/uuid)
OPENCTI_BASE_URL=http://localhost:8080
OPENCTI_HEALTHCHECK_ACCESS_KEY=$(cat /proc/sys/kernel/random/uuid)
OPENCTI_ENCRYPTION_KEY=$(openssl rand -base64 32)
MINIO_ROOT_USER=$(cat /proc/sys/kernel/random/uuid)
MINIO_ROOT_PASSWORD=$(cat /proc/sys/kernel/random/uuid)
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
ELASTIC_MEMORY_SIZE=4G
SMTP_HOSTNAME=localhost

CONNECTOR_HISTORY_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_CSV_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_TXT_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_DOCUMENT_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_ANALYSIS_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_OPENCTI_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_OPENCTI_MITRE=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_FILE_YARA_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_MITRE_ATLAS_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_EXTERNAL_REFERENCE_ID=$(cat /proc/sys/kernel/random/uuid)

GTI_API_KEY=${GTI_API_KEY}
URLSCAN_API_KEY=${URLSCAN_API_KEY}
ALIENVAULT_API_KEY=${ALIENVAULT_API_KEY}
GREYNOISE_API_KEY=${GREYNOISE_API_KEY}
OPEN_APPSEC_TOKEN=${OPEN_APPSEC_TOKEN}
EOF
) > .env

wget -O docker-compose.yml "https://raw.githubusercontent.com/repulsivityy/opencti/refs/heads/main/docker-compose.yml"
wget -O latest_docker.sh "https://raw.githubusercontent.com/repulsivityy/opencti/refs/heads/main/latest_docker.sh"
chmod 755 latest_docker.sh

cd ~/opencti
mkdir open-appsec-advance-model
cd open-appsec-advance-model
wget -O open-appsec-advanced-model.tgz https://github.com/repulsivityy/opencti/raw/refs/heads/main/open-appsec-advanced-model.tgz
cd ~/opencti

echo "####################"
echo "Bringing OpenCTI up"
echo "####################"
sudo docker compose up -d
