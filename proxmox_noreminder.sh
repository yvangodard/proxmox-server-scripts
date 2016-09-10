#!/bin/bash
# automatic removal of Proxmox subscription reminder during upgrades

# Variables initialisation
version="proxmoxNoReminder v0.1 - 2016, Yvan Godard [godardyvan@gmail.com]"
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
githubRemoteScript="https://raw.githubusercontent.com/yvangodard/proxmox-server-scripts/master/proxmox_noreminder.sh"

# Exécutable seulement par root
if [ `whoami` != 'root' ]; then
    echo "Ce script doit être utilisé par le compte root. Utilisez 'sudo'."
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
if [[ $(checkUrl ${githubRemoteScript}) -eq 0 ]] && [[ $(md5 -q "$0") != $(curl -Lsf ${githubRemoteScript} | md5 -q) ]]; then
    [[ -e "$0".old ]] && rm "$0".old
    mv "$0" "$0".old
    curl -Lsf ${githubRemoteScript} >> "$0"
    echo "Une mise à jour de ${0} est disponible." >> /var/log/incron.log
    echo "Nous la téléchargeons depuis GitHub." >> /var/log/incron.log
    if [ $? -eq 0 ]; then
        echo "Mise à jour réussie, nous relançons le script." >> /var/log/incron.log
        chmod +x "$0"
        exec ${0} "$@"
        exit $0
    else
        echo "Un problème a été rencontré pour mettre à jour ${0}." >> /var/log/incron.log
        echo "Nous poursuivons avec l'ancienne version du script." >> /var/log/incron.log
    fi
    echo ""
fi
IFS=$OLDIFS

# exit on error
set -e

# Since we are watching the whole directory, we need to check for the correct file
if [ "$1" == "pvemanagerlib.js.dpkg-tmp" ]; then

    echo "$(date +%Y-%m-%d_%H:%M) pvemanagerlib.js has been upgraded - patching file" >> /var/log/incron.log

    # wait a bit until the file has its permanent name
    sleep 10

    # patch the files
    cp /usr/share/pve-manager/ext6/pvemanagerlib.js /usr/share/pve-manager/ext6/pvemanagerlib.js.bak
    sed -i -r -e "s/if \(data.status !== 'Active'\) \{/if (false) {/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1
    sed -i -r -e "s/You do not have a valid subscription for this server/This server is receiving updates from the Proxmox VE No-Subscription Repository/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1
    sed -i -r -e "s/No valid subscription/Community Edition/" /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log 2>&1

    # log  the changes
    diff /usr/share/pve-manager/ext6/pvemanagerlib.js.bak /usr/share/pve-manager/ext6/pvemanagerlib.js >> /var/log/incron.log
fi

exit 0
