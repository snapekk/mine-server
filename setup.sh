#!/bin/bash

SERVER_DIR="$HOME/minecraft_server"
GITHUB_USER="snapekk"
REPO_NAME="mine-server"

echo "==========================================="
echo "===  INITIATING MULTI-VERSION SETUP     ==="
echo "==========================================="

if [ -n "$PREFIX" ] && [[ "$PREFIX" == *"/com.termux"* ]]; then
    echo "-> Installing Termux dependencies..."
    pkg update -y
    pkg install openjdk-17 wget curl git screen -y
    RAM="4G"
    JAVA_FLAGS="-XX:+UseG1GC"
else
    echo "-> Installing Ubuntu dependencies..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install openjdk-21-jre-headless screen wget curl git unzip -y
    RAM="6G"
    JAVA_FLAGS="-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+PerfDisableSharedMem"
fi

echo "-> Creating server directory..."
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR" || exit

echo "-> Fetching available versions from GitHub..."
git clone https://github.com/$GITHUB_USER/$REPO_NAME.git temp_repo -q

echo ""
echo "==========================================="
echo "===        SELECT SERVER VERSION        ==="
echo "==========================================="

cd temp_repo/mods || exit
VERSIONS=(*/)
VERSIONS=("${VERSIONS[@]%/}")
cd ../..

for i in "${!VERSIONS[@]}"; do
    echo "[$i] - Minecraft ${VERSIONS[$i]}"
done
echo "==========================================="

read -p "Enter the desired version number: " SELECTION < /dev/tty

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ -z "${VERSIONS[$SELECTION]}" ]; then
    echo "Invalid option. Aborting setup."
    rm -rf temp_repo
    exit 1
fi

VERSION="${VERSIONS[$SELECTION]}"
echo ""
echo "-> Selected version: $VERSION. Starting engines..."

wget -qO fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.jar
java -jar fabric-installer.jar server -mcversion "$VERSION" -downloadMinecraft

echo "eula=true" > eula.txt

cat <<EOF > server.properties
level-name=Servidor GGMax feito por Snape
motd=ggmax.com.br/perfil/snapezada
difficulty=hard
view-distance=12
simulation-distance=5
online-mode=false
network-compression-threshold=1024
EOF

echo "-> Injecting mods and configs for $VERSION..."
mkdir -p mods config
cp -r temp_repo/mods/"$VERSION"/* ./mods/
if [ -d "temp_repo/configs/$VERSION" ]; then
    cp -r temp_repo/configs/"$VERSION"/* ./config/
fi

rm -rf temp_repo fabric-installer.jar

mkdir -p config
cat <<EOF > config/c2me.toml
[threadedWorldGen]
allowThreadedFeatures = true
reduceLockRadius = true
[asyncScheduling]
enabled = true
[ioSystem]
replaceImpl = true
asyncMACThreads = 3
EOF

echo "-> Creating startup script..."
cat <<EOF > start.sh
#!/bin/bash
java -Xms$RAM -Xmx$RAM $JAVA_FLAGS -jar fabric-server-launch.jar nogui
EOF

chmod +x start.sh

echo "==========================================="
echo "===           SETUP COMPLETED!          ==="
echo "==========================================="
echo "To start, type:"
echo "cd $SERVER_DIR && screen -S mine ./start.sh"
