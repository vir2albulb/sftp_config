# sftp_config
Bash script that allows to configure SFTP account for particular user

Simply script to configure SFTP server (if never been configured) and SFTP account.

sft_config.sh requires only 2 parameters:
1. username
2. path to SFTP root directory.

If both parameters are correct in first step script create account (if not exists), set default shell to /sbin/nologin and home directory to SFTP root directory.
In next step correct ACLs are set to root SFTP directory for newly created SFTP account.
Last step is basic for sshd_config file - apply access using SFTP and add new SFTP account to be allowed only to connect using SFTP protocol.
