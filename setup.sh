#!/bin/bash

VERSION="1.20.4"
RAM="6G"
SERVER_DIR="$HOME/minecraft_server"
GITHUB_USER="snapekk"
REPO_NAME="mine-server"

echo "=== initiating Server ($VERSION) ==="

echo "-> Installing Ubuntu dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install openjdk-21-jre-headless screen wget curl git unzip -y

echo "-> Criating server directory..."
mkdir -p $SERVER_DIR
cd $SERVER_DIR

echo "-> Downloading and installing Minecraft and Fabric..."
wget -O fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.jar
java -jar fabric-installer.jar server -mcversion $VERSION -downloadMinecraft

echo "eula=true" > eula.txt

echo "-> Downloading mods folder..."
git clone https://github.com/$GITHUB_USER/$REPO_NAME.git temp_repo

cp -r temp_repo/mods ./

rm -rf temp_repo fabric-installer.jar

echo "-> Creating start script with ZGC..."
cat <<EOF > start.sh
#!/bin/bash
java -Xms$RAM -Xmx$RAM \\
-XX:+UseZGC \\
-XX:+ZGenerational \\
-XX:+AlwaysPreTouch \\
-XX:+DisableExplicitGC \\
-XX:+PerfDisableSharedMem \\
-jar fabric-server-launch.jar nogui
EOF

chmod +x start.sh

echo "==========================================="
echo "===             Sucess!                 ==="
echo "==========================================="
echo "To start, type:"
echo "cd $SERVER_DIR && screen -S mine ./start.sh"
