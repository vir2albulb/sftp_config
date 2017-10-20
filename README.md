# sftp_config
Requirements: bash shell

Script written and verified on Centos7.

Bash script that allows to configure SFTP account for particular user or group

Simply script to configure SFTP server and SFTP account.

sftp_config.sh requires only 3 parameters:
1. option -> 'user' or 'group'
1. userID or groupID
2. path to SFTP root directory.

Example for SFTP user:
```
./sftp_config.sh user sftp_user /sftp_share
```

Example for SFTP group:
```
./sftp_config.sh group sftp_group /sftp_share
```

If both parameters are correct in first step script creates account or group (if not 
exists), for user sets default shell to /sbin/nologin and home directory to SFTP root
directory.
In next step correct ACLs are set to root SFTP directory for newly created SFTP 
account/group.
Last step is basic for sshd_config file - apply access using SFTP and add new 
SFTP account to be allowed only to connect using SFTP protocol.

Script sets permissions to login to SFTP IDs using passwords.
