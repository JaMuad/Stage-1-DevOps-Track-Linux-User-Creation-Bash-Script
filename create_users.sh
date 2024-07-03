#!/bin/bash

# Run as root
if [ "$EUID" -ne 0 ]; then
  echo "Must be run as root"
  exit 1
fi

# Function to log actions timestamp
log_action() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to create a user and assign groups
create_user() {
  local username="$1"
  local groups="$2"

  # Trim whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

  # Checks against logs if user already exist in the logs (file)
  if id "$username" &>/dev/null; then
    log_action "User $username already exists. (No action taken)"
    return
  fi

  # Create group for the user if it doesn't exist
  if ! getent group "$username" &>/dev/null; then
    groupadd "$username"
    log_action "Group $username created."
  fi

  #Check if Group is missing or Group removed then either update or remove Group from user (missing code)

  # Create user with home directory and add group
  useradd -m -g "$username" -s /bin/bash "$username"
  log_action "User $username created with directory and group $username."

  # Generate a rand passwrd for new user
  password=$(openssl rand -base64 12)
  echo "$username:$password" | chpasswd
  log_action "Password for $username."

  # Securly store passwrd
  echo "$username,$password" | tee -a "$PASSWORD_FILE"

  # Add user to additional groups if specified
  if [ -n "$groups" ]; then
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
}

# Check if the input file is provided or manual flag is used

if [ -z "$1" ]; then
  echo "Usage: $0 <textfile.txt> or $0 --manual"
  exit 1
fi

# Define log action and password stroage 
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the directories and log file exist
mkdir -p /var/secure/
touch "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Debugging output
echo "DEBUG: LOG_FILE=$LOG_FILE"
echo "DEBUG: PASSWORD_FILE=$PASSWORD_FILE"

if [ "$1" == "--manual" ]; then
  # Manually user creation
  echo "Enter the username:"
  read username
  echo "Enter the groups ( use comma seperation for more than ONE group (e.g: dev,devops)):"
  read groups
  create_user "$username" "$groups"
else
  # Process the input file
  INPUT_FILE=$1
  while IFS=';' read -r username groups; do
    create_user "$username" "$groups"
  done < "$INPUT_FILE"
fi

log_action "User creation successful."
echo "User creation successful"

# Here we have two method to run bash 
#OPTION 1 - SUDO ./create_users.sh textfile.txt 
#OPTION 2 - SUDO ./create_users.sh --manual