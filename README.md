### Description
This repo was built based on how ich777 builds his unraid steam apps. 

Changes made to his files was to the start-server.sh, the file backs up before updating dragonwilds and restores after from the backup it due to a bug that would wipe the contents of your ini file.

It also runs the game using the binary instead of using srcds_run.

This is setup is as close to what I think ich777 would setup so hopefully it's easy to transfer to his app once he publishes.

If there is an update you should just have to restart the server and the new dedicated server files should download.

### Setup
1. Pull this repo down or copy the files somewhere on your server (I have them living in a folder in my shares folder on my array)
2. Run the `First Time Run` command below
3. Open the logs and wait for steamcmd, and the game to download and run so it creates the initial files you need
4. Stop the server
5. Modify `/mnt/{cache|user}/appdata/rsdw-dedicated/Saved/Config/LinuxServer/DedicatedServer.ini` - You can read what to put in the ini values from their docs https://dragonwilds.runescape.com/news/how-to-dedicated-servers
6. Start the server back up
7. Search for your server in the game (case sensitive)
7.1 If you are connecting from the same network there is a little checkbox at the bottom left of the game then when you connect you enter in the ip address of your server
8. After you get the server running I suggest setting up the Backup User Script

## First Time Run
This will build the image and then run it, you shouldn't need to do this except for the first time. After the first time you should be able to start/stop/restart from the Docker tab.

> **⚠️ WARNING:** I have my volumes mounted directly to cache since my appdata folder is only on my cache pool. If yours is not you need to change cache to user.
- These 2 lines:
```
-v /mnt/user/appdata/steamcmd:/serverdata/steamcmd:rw \
-v /mnt/user/appdata/rsdw-dedicated:/serverdata/serverfiles:rw \
```
```
docker build -t rsdw-dedicated:local . && \
docker run -d \
  --name=Dragonwilds \
  --restart unless-stopped \
  -e UID=99 \
  -e GID=100 \
  -e UMASK=000 \
  -e GAME_PORT=7777 \
  -e GAME_PARAMS="-log -NewConsole" \
  -e VALIDATE=0 \
  -v /mnt/cache/appdata/steamcmd:/serverdata/steamcmd:rw \
  -v /mnt/cache/appdata/rsdw-dedicated:/serverdata/serverfiles:rw \
  -p 7777:7777/udp \
  rsdw-dedicated:local
```

## Backup User Script
This script is under the pre-requisite that you have the user script plugin installed. You can update where the backups are saved by editing the `mv $backup_tar /mnt/user/backup/dragonwilds_backups` line.

This script will also only leave the last 6 backups to preserve space you can remove the lines for `cleaning up old backups`

I have this setup to run ever night at 4 am with `0 4 * * *` cron schedule.

If you need to restore from a backup you can run the following command `tar -xzvf dragonwilds-{date}.tar.gz -C /mnt/user/appdata/rsdw-dedicated/RSDragonwilds`

```
#!/bin/bash
# Stop Dragonwilds
echo "Stopping Dragonwilds"
docker stop Dragonwilds
echo "Dragonwilds stopped"

cd /mnt/user/appdata/rsdw-dedicated/RSDragonwilds

backup_tar="dragonwilds-$(date +"%Y-%m-%d-%H%M%S").tar.gz"

# tar dbs
echo "Compress Saved folder"
tar -czvf $backup_tar Saved
echo "Saved folder compressed"

# Start Dragonwilds
echo "Starting Dragonwilds"
docker start Dragonwilds
echo "Dragonwilds started"

# Create backup dir if it does not exist
mkdir -p /mnt/user/backup/dragonwilds_backups

echo "Moving tar"
mv $backup_tar /mnt/user/backup/dragonwilds_backups
echo "tar moved"

echo "cleaning up old backups"
cd /mnt/user/backup/dragonwilds_backups
ls -t dragonwilds*.tar.gz | tail -n +6 | xargs -r -d '\n' rm --
echo "old backups cleaned up"
```
