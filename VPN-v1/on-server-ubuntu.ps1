cd ~
unzip /tmp/wireguardVPN.zip -d wireguardVPN/
cd wireguardVPN/server

# Configure
cp config.env.example config.env
nano config.env  # Set SERVER_HOST to your domain/IP

# Install and test
chmod +x scripts/*.sh ../client/linux/*.sh
./scripts/setup-and-test.sh