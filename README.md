# proxmox-server-scripts
Various scripts for configuring and administering a Proxmox (Debian) server and VMs

#### Backup and Restore with S3QL

 - s3ql: an init script for mounting the s3ql encryped filesystem for use as a storage directory in Proxmox
 - s3ql_backup.sh: for backing up a whole Proxmox server with s3ql to Amazon S3 storage
 - s3ql_restore.sh:	for restoring a whole Proxmox server with 3sql from Amazon S3 storage

#### Networking in KVM Guests
 - setup_network.sh: for changing static network settings in Debian guest VM after cloning

#### Automatically remove Proxmox “No Valid Subscription” message on upgrades

The Proxmox “No Valid Subscription” message re-appears after each Proxmox software update, even if you initially patched the pve-manager file. Since Proxmox is free software under the GPL, I do not like the connotation of the message, which makes it sound like one is using unlicenced software. If you want to use the community repository for updates and do not need commercial support, it is completely legitimate to run Proxmox this way. If you want to use the 'enterprise repository', please look into the attractive [subscription options](https://www.proxmox.com/en/proxmox-ve/pricing).

###### How it works:

`proxmox_noreminder.sh`: this script automatically removes the Proxmox 3.4 “No Valid Subscription” message on upgrades by watching the relevant directory with `incron`. Incron is watching the directory, as it seems to trigger more reliably than watching only the file. A few files in this directory are replaced during each upgrade, but only one needs to be patched in this edition of Proxmox. The script also patches the Proxmox Support Tab with a more friendly message.

###### How to install:

- Check your `/etc/apt/sources.list` and make sure, that you are actually getting updates from the free [Proxmox repository](https://pve.proxmox.com/wiki/Package_repositories):

	`echo "deb http://download.proxmox.com/debian wheezy pve-no-subscription" >> /etc/apt/sources.list`
		
- Initially backup & patch the files manually and confirm with diff, that the changes are as expected:

	`wget http://bit.ly/proxmox_noreminder_init && mv proxmox_noreminder_init proxmox_noreminder_init.sh && chmod +x proxmox_noreminder_init.sh && ./proxmox_noreminder_init.sh`

- Test with (in another terminal):

	`tail -f /var/log/syslog | grep incrond`
	
	Reinstalling pve-manager should trigger incron:
	
	`apt-get install --reinstall pve-manager`
	
	and after, have a look to 
	
	`tail -n 30 -f /var/log/incron.log`



###### Disclaimer:
*The above scripts & patches may have unforeseen consequences and automatic patching could harm your system. Always backup your Proxmox system before applying such changes! Proxmox may change the code at any time, making the patches useless or even counterproductive. Please make sure you understand the code before applying it to your system. Also, IANAL, and in my opinion the above Proxmox patches are permitted under the GPL, but if want to make sure, please consult a copyright lawyer in your jurisdiction. This disclaimer should not be interpreted as legal advice.*

---
###### License:
This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
