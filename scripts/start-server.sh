#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +quit
fi

# Backup config before update
echo "---Backing up server config---"
CONFIG_FILE="${SERVER_DIR}/${GAME_NAME}/Saved/Config/LinuxServer/DedicatedServer.ini"
BACKUP_DIR="${DATA_DIR}/config_backups"
mkdir -p ${BACKUP_DIR}
if [ -f "${CONFIG_FILE}" ]; then
    cp "${CONFIG_FILE}" "${BACKUP_DIR}/DedicatedServer.ini.bak"
    echo "---Config backed up---"
else
    echo "---No existing config found, will create new one---"
fi

echo "---Update Server---"
if [ "${USERNAME}" == "" ]; then
    # Note: Avoid 'validate' flag as it can be destructive with config files
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login anonymous \
    +app_update ${GAME_ID} \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login ${USERNAME} ${PASSWRD} \
    +app_update ${GAME_ID} \
    +quit
fi

# Restore config after update
if [ -f "${BACKUP_DIR}/DedicatedServer.ini.bak" ]; then
    echo "---Restoring server config---"
    cp "${BACKUP_DIR}/DedicatedServer.ini.bak" "${CONFIG_FILE}"
fi

echo "---Prepare Server---"
if [ ! -f ${DATA_DIR}/.steam/sdk32/steamclient.so ]; then
	if [ ! -d ${DATA_DIR}/.steam ]; then
    	mkdir ${DATA_DIR}/.steam
    fi
	if [ ! -d ${DATA_DIR}/.steam/sdk32 ]; then
    	mkdir ${DATA_DIR}/.steam/sdk32
    fi
    cp -R ${STEAMCMD_DIR}/linux32/* ${DATA_DIR}/.steam/sdk32/
fi
chmod -R ${DATA_PERM} ${DATA_DIR}

# Ensure server binary is executable
chmod +x "${SERVER_DIR}/${GAME_BINARY}"
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
./${GAME_BINARY} ${GAME_PARAMS} -Port=${GAME_PORT}