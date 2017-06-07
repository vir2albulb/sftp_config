#!/usr/bin/env bash
user=$1
path=$2
sshd_config="/etc/ssh/sshd_config";

if [[ -n $user ]] && [[ -n $path ]]; then
	if [[ -d $path ]]; then
		id $user > /dev/null 2>&1;
		if [ $? -eq 0 ]; then
			echo "User ${user} already exists. It will be used as sftp ID";
			usermod -s /sbin/nologin -d "${path}" $user >/dev/null 2>&1;
		else
			echo "Creating user ${user}...";
			useradd -d "${path}" -s /sbin/nologin $user >/dev/null 2>&1;
			echo "Done. Please set password to newly created account using: passwd ${user}";
		fi
		setfacl -R -m u:$user:rwX "${path}";
		setfacl -R -m d:u:$user:rwX "${path}";
		cp "${sshd_config}" "${sshd_config}_$(date +%s)";
		grep -P "Subsystem\tsftp\tinternal-sftp" "${sshd_config}" > /dev/null 2>&1 || \
		sed -i 's/Subsystem\tsftp\t\/usr\/libexec\/openssh\/sftp-server/#&\nSubsystem\tsftp\tinternal-sftp/' "${sshd_config}";
		echo -e "Match user ${user}\n\tPasswordAuthentication yes\n\tForceCommand internal-sftp" >> "${sshd_config}";
		systemctl restart sshd > /dev/null 2>&1 || service sshd restart > /dev/null 2>&1;
		echo "SFTP account ${user} ready to use";
	else
		echo "Invalid path parameter";
	fi
else
	echo "Please make sure that both parameters are available.";
fi
