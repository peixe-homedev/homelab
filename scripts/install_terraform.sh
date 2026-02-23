# 1. Install dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# 2. Add the HashiCorp GPG key (proves the software is legit)
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# 3. Add the official repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# 4. Update and Install
sudo apt-get update && sudo apt-get install terraform
