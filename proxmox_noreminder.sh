#!/bin/bash
# automatic removal of Proxmox subscription reminder during upgrades

# Variables initialisation
version="proxmoxNoReminder v0.2 - 2016, Yvan Godard [godardyvan@gmail.com]"
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
githubRemoteScript="https://raw.githubusercontent.com/yvangodard/proxmox-server-scripts/master/proxmox_noreminder.sh"

# Exécutable seulement par root
if [ `whoami` != 'root' ]; then
    echo "This tool have to be launched by root. Please use 'sudo'."
    exit 1
fi

# Check URL
function checkUrl() {
  command -p curl -Lsf "$1" >/dev/null
  echo "$?"
}

# Changement du séparateur par défaut et mise à jour auto
OLDIFS=$IFS
IFS=$'\n'
# Auto-update script
if [[ $(checkUrl ${githubRemoteScript}) -eq 0 ]] && [[ $(md5sum "$0" | awk '{print $1}') != $(curl -Lsf ${githubRemoteScript} | md5sum | awk '{print $1}') ]]; then
    [[ -e "$0".old ]] && rm "$0".old
    mv "$0" "$0".old
    curl -Lsf ${githubRemoteScript} >> "$0"
    echo "An update for ${0} is available." >> /var/log/incron.log
    echo "We download it from GitHub." >> /var/log/incron.log
    if [ $? -eq 0 ]; then
        echo "Update ok, relaunching the script." >> /var/log/incron.log
        chmod +x "$0"
        exec ${0} "$@"
        exit $0
    else
        echo "Something went wrong when trying to upgrade ${0}." >> /var/log/incron.log
        echo "We continue with the old version of the script." >> /var/log/incron.log
    fi
    echo ""
fi
IFS=$OLDIFS

# exit on error
set -e

# Since we are watching the whole directory, we need to check for the correct file
if [ "$1" == "pvemanagerlib.js.dpkg-tmp" ]; then

    echo ""  >> /var/log/incron.log
    echo "****************************** `date` ******************************"  >> /var/log/incron.log
    echo "$0 launched..." >> /var/log/incron.log
    echo "" >> /var/log/incron.log

    echo "File pvemanagerlib.js has been upgraded - patching this file" >> /var/log/incron.log
    echo "" >> /var/log/incron.log

    # wait a bit until the file has its permanent name
    sleep 15

    if [[ -e /usr/share/pve-manager/ext6/pvemanagerlib.js ]]; then
        # patch the files
        cp /usr/share/pve-manager/ext6/pvemanagerlib.js /usr/share/pve-manager/ext6/pvemanagerlib.js.bak
        sed -i -r -e "s/if \(data.status !== 'Active'\) \{/if (false) {/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1
        sed -i -r -e "s/You do not have a valid subscription for this server/This server is receiving updates from the Proxmox VE No-Subscription Repository/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1
        sed -i -r -e "s/No valid subscription/Community Edition/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1

        # log  the changes
        echo "Here are changes: " >> /var/log/incron.log
        diff /usr/share/pve-manager/ext6/pvemanagerlib.js.bak /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log
    elif [[ -e /usr/share/pve-manager/js/pvemanagerlib.js ]]; then
        # patch the files
        cp /usr/share/pve-manager/js/pvemanagerlib.js /usr/share/pve-manager/js/pvemanagerlib.js.bak
        sed -i -r -e "s/if \(data.status !== 'Active'\) \{/if (false) {/" /usr/share/pve-manager/js/pvemanagerlib.js >> /var/log/incron.log 2>&1
        sed -i -r -e "s/You do not have a valid subscription for this server/This server is receiving updates from the Proxmox VE No-Subscription Repository/" /usr/share/pve-manager/js/pvemanagerlib.js >> /var/log/incron.log 2>&1
        sed -i -r -e "s/No valid subscription/Community Edition/" /usr/share/pve-manager/js/pvemanagerlib.js >> /var/log/incron.log 2>&1

        # log  the changes
        echo "Here are changes: " >> /var/log/incron.log
        diff /usr/share/pve-manager/js/pvemanagerlib.js.bak /usr/share/pve-manager/js/pvemanagerlib.js >> /var/log/incron.log
    fi     

fi

exit 0
