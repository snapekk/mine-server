#!/bin/bash

VERSION="1.20.4"
RAM="6G"
SERVER_DIR="$HOME/minecraft_server"
GITHUB_USER="snapekk"
REPO_NAME="mine-server"

echo "=== initiating Server ($VERSION) ==="

if [ -n "$PREFIX" ] && [[ "$PREFIX" == *"/com.termux"* ]]; then
    echo "-> Installing Termux dependencies..."
    pkg update -y
    pkg install openjdk-17 wget curl git screen -y
    JAVA_FLAGS="-XX:+UseZGC -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+PerfDisableSharedMem"
else
    echo "-> Installing Ubuntu dependencies..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install openjdk-21-jre-headless screen wget curl git unzip -y
    JAVA_FLAGS="-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+PerfDisableSharedMem"
fi

echo "-> Creating server directory..."
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR" || exit

echo "-> Downloading and installing Minecraft and Fabric..."
wget -O fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.jar
java -jar fabric-installer.jar server -mcversion $VERSION -downloadMinecraft

echo "eula=true" > eula.txt

cat <<EOF > server.properties
online-mode=false
view-distance=8
simulation-distance=5
network-compression-threshold=128
EOF

echo "-> Downloading mods folder..."
git clone https://github.com/$GITHUB_USER/$REPO_NAME.git temp_repo

cp -r temp_repo/mods ./
rm -rf temp_repo fabric-installer.jar

mkdir -p config
cat <<EOF > config/c2me.toml
[threadedWorldGen]
    allowThreadedFeatures = "true"
    reduceLockRadius = "true"
[asyncScheduling]
    enabled = "true"
[ioSystem]
    replaceImpl = "true"
    asyncMACThreads = 3
EOF

echo "-> Creating start script with ZGC..."
cat <<EOF > start.sh
#!/bin/bash
java -Xms$RAM -Xmx$RAM $JAVA_FLAGS -jar fabric-server-launch.jar nogui
EOF

chmod +x start.sh

echo "==========================================="
echo "===             Success!                 ==="
echo "==========================================="
echo "To start, type:"
echo "cd $SERVER_DIR && screen -S mine ./start.sh"
