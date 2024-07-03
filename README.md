
# Automate Manage Users and Groups with a Bash Script

## Introduction
Okay, we are here to transform your SysOps workflow with a simple Bash script that automates user and group management effortlessly. 

This blog post is part of a series aimed to preserving kowledge for my future self study guide by  creating more project of this nature helping me connect with like minded techies. Join me as we explore how to automate user and group management seamlesssly with a Bash script. 

Let's get started!

## Follow these prerequisites and you're good to go executing your bash script
### - Linux Environment:
Choose a Linux environment that suits your needs. For this blog, I'm using <u>Kali OS version 2022.4</u> (Debian-based).
### - Install Visual Studio Code (Optional, you can execute the script in terminal using editors like Vim, Vi, or Nano) 
### - Create Necessary Directories:
Ensure the directories required by the script are available.
`sudo mkdir -p /var/secure/`
### - Set Permissions:
Set appropriate permissions for the directories and files.
`sudo touch /var/log/user_management.log`
`sudo touch /var/secure/user_passwords.csv`
`sudo chmod 600 /var/secure/user_passwords.csv`
### - Install Required Utilities:
Make sure all necessary utilities are installed. These are usually pre-installed, but you can always check them again.
`sudo apt-get update`
`sudo apt-get install passwd coreutils openssl`
### - Prepare your Bash File:

#### - Shebang

![Preparing your Bash file](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5e4g02ne7oimd078g5uy.png)
`#!/bin/bash`
Specifies the code runs in Bash shell

#### - Specify your script to run in root

![Must run as root](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xtdjfzdgwyvs527py5f9.png)

`if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi`
It will alert an error message if you don't use script the code in root

#### - Function to log actions timestamp

`log_action() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}`
Logs each record with a timestamp to the log file. The tee -a command appends the message to the log file and also displays it on the terminal.

#### - Function to create a user and assign groups
`create_user() {
  local username="$1"
  local groups="$2"`
When calling create_user function with two arguments, the first argument will be stored in the username variable which also represents the ('$1') as first argument and the second argument will be stored in the groups variable ('$1'). 
#### - Trim whitespace
  `username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)`
Trims any leading or trailing whitespace from the username and groups variables while using the xargs command.

#### - Checks against logs if user already exist in the logs (file)
  `if id "$username" &>/dev/null; then
    log_action "User $username already exists. (No action taken)"
    return
  fi`
This code checks if the user specified by username exists, and if so, logs a message and exits the function without taking any further action.

#### - Create group for the user if it doesn't exist
  `if ! getent group "$username" &>/dev/null; then
    groupadd "$username"
    log_action "Group $username created."
  fi`
It simply creates new user group if group is missing.

#### - Create user with home directory and add group
  `useradd -m -g "$username" -s /bin/bash "$username"
  log_action "User $username created with directory and group $username."`
It simply creates new user.

#### - Generate a rand passwrd for new user
  `password=$(openssl rand -base64 12)
  echo "$username:$password" | chpasswd
  log_action "Password for $username."`
This code generates a random password for the new user, sets it, and logs the action.

#### - Securly store passwrd
  `echo "$username,$password" | tee -a "$PASSWORD_FILE"`
the values stored in the $username and $password combines them into a single string separated by a comma, and then appends this string to the file specified by $PASSWORD_FILE and it prints on the terminal as well.

#### - Add user to additional groups if specified
  `if [ -n "$groups" ]; then
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
      group=$(echo "$group" | xargs)
      if ! getent group "$group" &>/dev/null; then
        groupadd "$group"
        log_action "Group $group created."
      fi
      usermod -aG "$group" "$username"
      log_action "User $username added to group $group."
    done
  fi
}`

#### - Check if the input file is provided or manual flag is used

`if [ -z "$1" ]; then
  echo "Usage: $0 <textfile.txt> or $0 --manual"
  exit 1
fi`

#### - Define log action and password stroage 
`LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"`

#### - Ensure the directories and log file exist
`mkdir -p /var/secure/
touch "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"`

#### - Debugging output
`echo "DEBUG: LOG_FILE=$LOG_FILE"
echo "DEBUG: PASSWORD_FILE=$PASSWORD_FILE"
if [ "$1" == "--manual" ]; then
  echo "Enter the username:"
  read username
  echo "Enter the groups ( use comma seperation for more than ONE group (e.g: dev,devops)):"
  read groups
  create_user "$username" "$groups"
else
  INPUT_FILE=$1
  while IFS=';' read -r username groups; do
    create_user "$username" "$groups"
  done < "$INPUT_FILE"
fi`
`
log_action "User creation successful."
echo "User creation successful"`

### - Reads a text file of employee usernames and group names, formatted as user;groups per line:

![Creating textfile.txt](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/tuxl373sg8nhe4yc1ou8.png)

Create a text file containing the usernames and groups in the format user;groups. Each line should represent a user and their associated groups.

Include a plain text file called 'textfile.txt' and add this data: 

`username1;a,admin
username2;dev
username3;devops,admin`

### - Script Execution:

Script executable command then run it. Your 'create_users.sh' file head to the directory your file is saved and then execute the command.

`chmod +x create_users.sh`

#### Here we have two method to run the bash script
 
OPTION 1 - `SUDO ./create_users.sh textfile.txt` 
OPTION 2 - `SUDO ./create_users.sh --manual`

### - Results in command line
-When using command sudo ./create_users.sh textfile.txt here is the result. 

![creating new users and group result](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/atnjq1g72my3h1jq29l1.png)

When using command sudo ./create_users.sh --manual here is the result.

![using manual input](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/2kjb1pj9r3h05ra39952.png)

### - Testing exisitng created User
Rejected input when exisitng user was found in the logs. 

![Not updated to the data log](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/k5tq3kkhr9tawnzoe4oq.png)

THE END
