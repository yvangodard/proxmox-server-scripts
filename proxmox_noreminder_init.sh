#!/bin/bash

# Variables initialisation
version="proxmoxNoReminder v0.1 - 2016, Yvan Godard [godardyvan@gmail.com]"
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
githubRemoteScript="https://raw.githubusercontent.com/yvangodard/proxmox-server-scripts/master/proxmox_noreminder_init.sh"

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
	echo "Une mise à jour de ${0} est disponible."
	echo "Nous la téléchargeons depuis GitHub."
	if [ $? -eq 0 ]; then
		echo "Mise à jour réussie, nous relançons le script."
		chmod +x "$0"
		exec ${0} "$@"
		exit $0
	else
		echo "Un problème a été rencontré pour mettre à jour ${0}."
		echo "Nous poursuivons avec l'ancienne version du script."
	fi
	echo ""
fi
IFS=$OLDIFS

echo ""
echo "Nous allons installer CURL si ce n'est pas déjà fait..."
apt-get install curl

echo ""
echo "Nous allons installer INCRON si ce n'est pas déjà fait..."
apt-get install incron

echo ""
echo "Nous ajoutons une table ROOT dans INCRON si ce n'est pas déjà fait..."
[[ ! -e /etc/incron.allow ]] && echo "root" >> /etc/incron.allow
cat /etc/incron.allow | grep root > /dev/null 2>&1
[ $? -ne 0 ] && echo "root" >> /etc/incron.allow

echo ""
echo "Nous allons créer le dossier /etc/incron.scripts si ce n'est pas déjà fait..."
[[ ! -d /etc/incron.scripts ]] && mkdir -v "/etc/incron.scripts"

echo ""
echo "On installe proxmox_noreminder.sh dans /etc/incron.scripts si ce n'est pas déjà fait..."
[[ -e /etc/incron.scripts/proxmox_noreminder.sh ]] && rm -R /etc/incron.scripts/proxmox_noreminder.sh
curl -Lsf https://raw.githubusercontent.com/yvangodard/proxmox-server-scripts/master/proxmox_noreminder.sh >> /etc/incron.scripts/proxmox_noreminder.sh
chmod +x /etc/incron.scripts/proxmox_noreminder.sh

cp /usr/share/pve-manager/ext6/pvemanagerlib.js /usr/share/pve-manager/ext6/pvemanagerlib.js.bak
sed -i -r -e "s/if \(data.status !== 'Active'\) \{/if (false) {/" /usr/share/pve-manager/ext6/pvemanagerlib.js 
sed -i -r -e "s/You do not have a valid subscription for this server/This server is receiving updates from the Proxmox VE No-Subscription Repository/" /usr/share/pve-manager/ext6/pvemanagerlib.js 
sed -i -r -e "s/No valid subscription/Community Edition/" /usr/share/pve-manager/ext6/pvemanagerlib.js

diff /usr/share/pve-manager/ext6/pvemanagerlib.js.bak /usr/share/pve-manager/ext6/pvemanagerlib.js

exit 0