#!/usr/bin/env bash

##################################################
## This script logs an AWS IAM user using configured
## MFA device token and sets session expiration
## to default of 12 hours
##################################################

usage () {
cat > /dev/stderr <<USAGE
  Usage: $(basename "$0") <OPTIONS> | [-?]

  REQUIRED FLAGS
  -u    AWS IAM username
  -t    six digit token from MFA device
  -v    verbose mode
  -e    expiration in seconds, default is 43200 (12 hours) the max is 129600 (36 hours). Will accept 'max' as option to set maximum expiration time

USAGE
  exit 42
}

# option handling
[ -z "$1" ] || [ "$1" = "--help" ] && usage
while getopts ":u:t:ve:" opt; do
  case $opt in
    u) user=${OPTARG};;
    t) token=${OPTARG};;
    v) verbose=1;;
    e) expiration=${OPTARG};;
    *) printf \\n"ERROR: unknown option -%s"\\n\\n "$OPTARG"; usage;;
  esac
done

[ -z "$user" ] || [ -z "$token" ] && printf \\n"!!!Missing required parameter..."\\n\\n && usage

# defaults
[ -z "$expiration" ] && expiration="43200"
[ "$(awk '{print tolower($0)}' 2>/dev/null <<< "$expiration")" = "max" ] && expiration="43200"
awsvars=('SecretAccessKey' 'SessionToken' 'AccessKeyId')
awsvarscred=('aws_secret_access_key' 'aws_session_token' 'aws_access_key_id')
awscredfile=~/.aws/credentials

# verbose mode
print () {
  local verb="$1"; shift
  local new="$1"; shift
  local message="$1"
  if [ -n "$verbose" ] || [ "$verb" = "v" ]; then
    if [ "$new" = "nl" ]; then echo "${message}"$'\n';
    else echo "${message}";
    fi
  fi
}

check_bin () {
  for i in "$@"; do
    local bin_to_check="$1"; shift
    if [ -z "$(which "$bin_to_check")" ]; then
      echo "$bin_to_check is not installed in your path. Exiting..." && exit 1;
    fi
  done
}

check_get () {
  local variable="$1"; shift
  local name="$1"
  print n nl "Session output = $variable"
  if [ -z "$variable" ]; then
    echo "Unable to get ${name}! Something went wrong... Exiting." && exit 1;
  fi
}

# list mfa devices for inputed user and get SerialNumber
get_user_mfa_arn () {
  local output="$1"
  print n "Getting mfa device arn: aws iam list-mfa-devices --user-name $user --output $output"
  sn=$(aws iam list-mfa-devices --user-name "$user" --output json | jq -r ."MFADevices[]"."SerialNumber")
  print n "MFADevice SerialNumber = ${sn}"
}

# clear the aws vars, get-session-token wont work if these vars are set (these are used in AWS config)
clean_aws_vars () {
  local file="$1"

  print n "Backing up current $file ... unsetting AWS env vars: ${awsvarscred[*]} ..."

  # reads cred file into array line by line
  local awscredfile_array=()
  while read LINE; do
    awscredfile_array+=("$LINE")
  done < "$file"

  # get position of new vars lines using #AWS_vars added comments
  local index=1
  local start_end=()
  for i in "${awscredfile_array[@]}"; do
    if [[ "$i" == *"#AWS_vars added"* ]]; then
      start_end+=($index)
    fi
    index=$(($index + 1))
  done

  # remove lines or do nothing if they are not present
  if [ ${#start_end[@]} -eq 1 ]; then
    start_end[1]=$((${start_end[0]} + 3))
    /usr/bin/sed -i_backup -e "${start_end[0]},${start_end[1]}d" -e 's/#//' "$file"
  elif [ ${#start_end[@]} -eq 2 ]; then
    /usr/bin/sed -i_backup -e "${start_end[0]},${start_end[1]}d" -e 's/#//' "$file"
  elif [ ${#start_end[@]} -gt 2 ]; then
    echo "Something went wrong when reading $file. Exiting."; exit 1
  elif [ ${#start_end[@]} -eq 0 ]; then
    : #do nothing
  fi
}

# get session token vars used in set_aws_var
get_session_token () {
  echo "Getting session token: aws sts get-session-token --serial-number $sn"
  echo "                                                 --token-code $token --duration-seconds $expiration"
  session_output=$(aws sts get-session-token --serial-number "$sn" --token-code "$token" --duration-seconds $expiration)
}

# sets aws variables in credentials file. Comments out user configured creds and appends script generated creds from get-session-token
set_aws_var () {
  # comment out user creds MAKE SURE YOU KEEP THESE VARS!! YOU WILL NEED THEM TO RE AUTH NEXT TIME!!
  /usr/bin/sed -i_backup -e 's/aws_access_key_id/#aws_access_key_id/' -e 's/aws_secret_access_key/#aws_secret_access_key/' $awscredfile
  print n nl "Setting AWS env vars: aws_secret_access_key, aws_session_token, aws_access_key_id..."
  echo "#AWS_vars added by ${0}" >> "$1"
  local j=0
  for i in "${awsvars[@]}"; do
    echo "${awsvarscred[j]} = $(echo "$session_output" | jq -r .Credentials."$i")" >> "$1"
    j=$((j+1))
  done
  echo "#AWS_vars added by ${0}" >> "$1"
  local expire=$(echo "$session_output" | jq -r .Credentials.Expiration)
  echo "MFA successful! Your session will expire at ${expire}"
}

# print out some script requirements
print v n ""
print n n "This script requires:"
print n n "- jq version 1.5+ in your path"
print n n "- awscli configured and in your path"

# main
check_bin jq
clean_aws_vars $awscredfile
get_user_mfa_arn json
check_get "$sn" "MFA Device SerialNumber"
get_session_token
check_get "$session_output" "session token"
set_aws_var $awscredfile
