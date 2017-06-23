#!/usr/bin/env bash

function show_help()
{
cat << EOF
# List of arguments:
# $1 -> option: 'user' or 'group'
# $2 -> user ID or group ID
# $3 -> path to SFTP share
#
# Create SFTP share and assign to user ID:
# sh sftp_config.sh user sftp_user /my_new_sftp_share
#
# Create SFTP share and assign to group ID:
# sh sftp_config.sh group sftp_group /my_new_sftp_share
EOF
}

function sftp_directory()
{
        if [[ ! -d $path ]]; then
                mkdir -p $path > /dev/null 2>&1;
                if [ $? -ne 0 ]; then
                        echo "Issue while creating ${path}. Please check if path is correct or create directory manually and then re-run script.";
                        exit 1;
                fi
        fi

        #execute permission to others on sftp dir
        path=$(cd $path; pwd -P $path);
        for (( i=2; i<$(echo $path | tr '/' '\n' | wc -l); i++ )); do
                file="$(echo $path | cut -d'/' -f1-"${i}")";
                chmod o+x $file > /dev/null 2>&1;
                if [ $? -ne 0 ]; then
                        echo "Issue with setting execute permissions for others to path ${file}. Please run script with proper access.";
                        exit 1;
                fi
                unset file
        done
}

option=$1
id=$2
path=$3
sshd_config="/etc/ssh/sshd_config";

if [[ -n $option ]] && [[ -n $id ]] && [[ -n $path ]] && ! $(echo $path | grep '\' > /dev/null 2>&1); then
	if [ $(echo $option | awk '{print tolower($0)}') == 'user' ]; then	
		sftp_directory;
                id $id > /dev/null 2>&1;
                if [ $? -eq 0 ]; then
                        echo "User ${id} already exists. It will be used as sftp ID";
                        usermod -s /sbin/nologin -d "${path}" $id >/dev/null 2>&1;
                else
                        echo "Creating user ${id}...";
                        useradd -d "${path}" -s /sbin/nologin $id >/dev/null 2>&1;
			read -p "Please set up password for user ${id}: " -s pass;
			echo "${pass}" | passwd $id --stdin > /dev/null 2>&1;
                        echo "Done.";
			unset pass;
			
                fi
                setfacl -R -m u:$id:rwX "${path}";
                setfacl -R -m d:u:$id:rwX "${path}";
                cp "${sshd_config}" "${sshd_config}_$(date +%s)";
                grep -P "Subsystem\tsftp\tinternal-sftp" "${sshd_config}" > /dev/null 2>&1 || \
                sed -i 's/Subsystem\tsftp\t\/usr\/libexec\/openssh\/sftp-server/#&\nSubsystem\tsftp\tinternal-sftp/' "${sshd_config}";
                echo -e "Match user ${id}\n\tPasswordAuthentication yes\n\tForceCommand internal-sftp" >> "${sshd_config}";
                systemctl restart sshd > /dev/null 2>&1 || service sshd restart > /dev/null 2>&1;
                echo "SFTP account ${id} ready to use";

	elif [ $(echo $option | awk '{print tolower($0)}') == 'group' ]; then
		sftp_directory;
		grep "${id}:" /etc/group > /dev/null 2>&1;
		if [ $? -ne 0 ]; then
			echo "Group ${id} not exists. Creating...";
			groupadd $id;
			echo "New group ${id} has been created.";
		fi
		setfacl -R -m g:$id:rwX "${path}";
                setfacl -R -m d:g:$id:rwX "${path}";
                cp "${sshd_config}" "${sshd_config}_$(date +%s)";
                grep -P "Subsystem\tsftp\tinternal-sftp" "${sshd_config}" > /dev/null 2>&1 || \
                sed -i 's/Subsystem\tsftp\t\/usr\/libexec\/openssh\/sftp-server/#&\nSubsystem\tsftp\tinternal-sftp/' "${sshd_config}";
                echo -e "Match group ${id}\n\tPasswordAuthentication yes\n\tForceCommand internal-sftp" >> "${sshd_config}";
                systemctl restart sshd > /dev/null 2>&1 || service sshd restart > /dev/null 2>&1;
                echo -e "SFTP group ${id} ready to use. To assign user to this group use:\nuseradd -g ${id} -d ${path} -s /sbin/nologin user_id OR for existing users\nusermod -g ${id} -d ${path} -s /sbin/nologin user_id";

	else
		echo "Incorrect option parameter. Please verify it.";
		show_help;
	fi
else
	echo "Please make sure that all parameters are valid.";
	show_help;
	exit 1;
fi
