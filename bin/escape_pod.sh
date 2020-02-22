#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"; cd "${DIR}" # get script path
source "${DIR}/aws_sts_session_check.sh" # checks aws sts session and prompts to login
source "${DIR}/lib/send_slack.sh"

##################################################
## Launch a number of EC2 instances from an
## launch-template
##################################################


usage () {
cat > /dev/stderr <<USAGE

  Lanch a number of EC2 instances from specified launch-template in specified region

  Usage: $(basename "$0") <OPTIONS> | [--help]

  REQUIRED FLAGS

  -c  count of instances to create in region

  -r  region (ap-south-1|eu-west-3|eu-west-2|eu-west-1|ap-northeast-2|ap-northeast-1|sa-east-1|ca-central-1|ap-southeast-1|ap-southeast-2|eu-central-1|us-east-1|us-east-2|us-west-1|us-west-2)
      Hint: (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)
      us-west-2=oregon   us-east-1= n. virginia
      eu-central-1=frankfurt
      eu-west-1=ireland   eu-west-2=london   eu-west-3=paris

  OPTIONAL FLAGS

  -d  set dry-run flag

  -i  attach elastic-ips to new instances

  -p  run latest puppet artifact on new instances

  NOTE:
  An authenticated AWS session is required. See bin/aws_mfa_set.sh

USAGE
  exit 42
}

# option handling
[ -z "$1" ] || [ "$1" = "--help" ] && usage
while getopts ":dic:pr:" opt; do
  case $opt in
    d) dry_run="--dry-run";;
    i) attach_el_ips=1;;
    c) count_instances=${OPTARG};;
    p) run_puppet=1;;
    r) region=${OPTARG};;
    *) printf \\n"ERROR: unknown option -%s"\\n\\n "$OPTARG"; usage;;
  esac
done

[ -z "$count_instances" ] || [ -z "$region" ] && printf \\n"!!!Missing required parameter..."\\n\\n && usage

# defaults
[ -z "$dry_run" ] && dry_run="--no-dry-run"
region="${region:-us-west-2}"
template_id=()
slack_channel="#aws_notifications"

# lots of kludge here, sorry
# TODO: fix the said kludge
# List launch-templates out so that the user can see available launch-templates to use
list_launch_templates () {
  printf \\n"Available templates to launch in $region region:"\\n
  local number_of_templates="$(aws ec2 describe-launch-templates --region $region | jq -r '.LaunchTemplates[]' | grep -o LaunchTemplateId | sort | uniq -c | awk '{print $1}')"
  local count=0
  while [ 0 -lt $number_of_templates ]; do
    printf "%s: " $count
    aws ec2 describe-launch-templates --region $region | jq -r .LaunchTemplates[$count].LaunchTemplateName
    template_id+=($(aws ec2 describe-launch-templates --region $region | jq -r .LaunchTemplates[$count].LaunchTemplateId))
    number_of_templates=$(($number_of_templates - 1))
    count=$(($count + 1))
  done
}

# get user input on which template to use (displays name of launch template but uses id with list_luanch_template)
prompt_templates () {
  printf \\n"Enter the template number to use"\\n
  printf :; read template_input
}

# Get the first public subnet in specified region and set as var: subnet
# 1: the aws region to use
get_subnet_public () {
  subnet=$(aws ec2 describe-subnets --region $region | jq -r '.Subnets[] | select(.MapPublicIpOnLaunch==true) | .SubnetId' | head -1)
}

# Launches a number of instances via a specified launch-template in a public subnet of a region (see get_subnet_public)
# 1: the aws region to use  2: number of instances to launch via launch-template
launch_instance_from_template () {
  local count_instances="$1"; shift

  get_subnet_public
  [ -z "$subnet" ] && echo "ERROR: Not able to get subnet-id. Exiting." && exit 1

  # capture output in var to parse out if not dry run mode
  if [ "$dry_run" == "--no-dry-run" ]; then

    output=$(aws ec2 run-instances --count $count_instances --region $region --launch-template LaunchTemplateId=${template_id[${template_input}]} --subnet-id ${subnet} $dry_run | tee /dev/tty)
    local instances=$(echo "$output" | jq -r '[.Instances[].InstanceId] | @csv' | sed -e 's/","/, /g' -e 's/"//g')
    send_slack "$slack_channel" "${BASH_SOURCE[0]}" "Creating the following EC2 instances: $instances in the $region region via ${BASH_SOURCE[0]} by $(whoami)"
  else
    aws ec2 run-instances --count $count_instances --region $region --launch-template LaunchTemplateId=${template_id[${template_input}]} --subnet-id ${subnet} $dry_run
  fi
}

# This allows elastic ips that match the awsprwdp* pattern to be associated to the just created instances. It does so by sorting the available unassoicated
# elastic ips that match the pattern and sorts them by name and attaches one at a time.
attach_elastic_ips () {
  if [ "$attach_el_ips" == "1" ]; then
    local json_output="$1"; shift

    local instancesid_array=($(echo "$json_output" | jq -r .Instances[].InstanceId))
    local ips_array=($(aws ec2 describe-addresses --region $region --filters "Name=tag:Name,Values=awsprwdp*" --query 'Addresses[?InstanceId==null]' --output json | jq -r 'sort_by(.Tags[].Value) | .[].PublicIp'))
    local alloc_array=($(aws ec2 describe-addresses --region $region --filters "Name=tag:Name,Values=awsprwdp*" --query 'Addresses[?InstanceId==null]' --output json | jq -r 'sort_by(.Tags[].Value) | .[].AllocationId'))
    local names_arary=($(aws ec2 describe-addresses --region $region --filters "Name=tag:Name,Values=awsprwdp*" --query 'Addresses[?InstanceId==null]' --output json | jq -r 'sort_by(.Tags[].Value) | .[].Tags[].Value'))

    # check arrays are the same size
    [ ${#alloc_array[@]} -ne ${#names_arary[@]} ] && echo "ERROR: Something went wrong with generating elastic_ip arrays, lengths did not match. Exiting." && exit 1

    # attach elastic ips
    echo $'\n'"##########Attaching elastic-ips to new instances...##########"$'\n'
    sleep 10 #sleeping to let enter inter a state where it can have an elasticip attached
    local index=0
    for i in "${instancesid_array[@]}"; do
      aws ec2 associate-address --region $region --instance-id "$i" --allocation-id "${alloc_array[$index]}" --no-allow-reassociation
      # print which elastic ips where associated to which nodes
      echo "INFO: $( date +%Y-%m-%d\ %H:%M:%S\ %Z ) The ip: ${ips_array[$index]} was attached to instance-id: ${i}"
      index=$(($index + 1))
    done
  fi
}

run_puppet () {
  if [ "$run_puppet" == "1" ]; then
    local json_output="$1"; shift

    echo -e "To run latest \033[31;1mlocal-to-the-node\033[0m puppet artifact via and iodpeloy please input your \033[1musername\033[0m. [Input format: firstinitiallastname (ex: jdavila)]"
    echo "This will use the inputted username to ssh on to each instance and run puppet twice with iodeploy."
    echo "Two iodeploys are needed to correctly configure the node. This can take a few minutes per node per each run."
    echo -e "If you do not want to run iodeploys on the new instances hit the ejector seat button with \033[31;1mcontol-c\033[0m. Note: this will not unamke the instances just created."
    printf : ; read username_input

    echo $'\n'"##########Fetching instance public DNS names to run latest puppet artifact##########"$'\n'
    sleep 60 #sleeping to let instance enter a state where it can have an elasticip attached
    local instancesid_array=($(echo "$json_output" | jq -r .Instances[].InstanceId))
    local instance_dns_names=()
    # making array of public DNS names of instances from instance-ids
    for i in "${instancesid_array[@]}"; do
      instance_dns_names+=($(aws ec2 describe-instances --region $region --instance-id "$i" | jq -r '.Reservations[].Instances[].PublicDnsName'))
    done

    for i in "${instance_dns_names[@]}"; do
      echo "INFO: $( date +%Y-%m-%d\ %H:%M:%S\ %Z ) Running first iodeploy on ${i}..."
      /usr/bin/ssh -o AddKeysToAgent=yes -o StrictHostKeyChecking=no "$username_input"@"$i" /tmp/latest_puppet_artifact/bin/iodeploy
      echo "INFO: $( date +%Y-%m-%d\ %H:%M:%S\ %Z ) Running second iodeploy on ${i}..."
      /usr/bin/ssh -o AddKeysToAgent=yes -o StrictHostKeyChecking=no "$username_input"@"$i" /tmp/latest_puppet_artifact/bin/iodeploy
      echo "INFO: $( date +%Y-%m-%d\ %H:%M:%S\ %Z ) Completed iodeploys on ${i}"
    done

    echo "INFO: $( date +%Y-%m-%d\ %H:%M:%S\ %Z ) Completed iodeploys on all instances: ${instancesid_array[@]}"
  fi
}

# main
session_check # make sure user has active session
list_launch_templates
prompt_templates
launch_instance_from_template $count_instances
attach_elastic_ips "$output"
run_puppet "$output"