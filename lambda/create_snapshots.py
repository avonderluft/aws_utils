################################
# Create EC2 snapshots on a regular schedule
#
# tested on AWS Lambda with Python 3.8
#
# functions by accessing tags on EC2 instances:
# - 'backup' with any value, to regularly snapshot this instance
# - 'retention' with value = number of days to keep the snapshots.
#
# Create a CloudWatch event rule to schedule your script to run regulary.
#
# To integrate with Slack, add ENV variables in the lambda setup:
# SLACK_CHANNEL
# SLACK_HOOK_URL
# If you are NOT using Slack, comment the last line in this
# script, (post_to_slack).
#
################################

import sys
import boto3
import re
import collections
import datetime
import os
import json
import subprocess

# pip install package to /tmp/ and add to path
subprocess.call('pip install requests -t /tmp/ --no-cache-dir'.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sys.path.insert(1, '/tmp/')
import requests

ec = boto3.client('ec2')
iam = boto3.client('iam')

def post_to_slack(text, instance_name, snapshot_count, expire_date):
    webhook_url = os.environ['SLACK_HOOK_URL']
    slack_data = {
        "channel": os.environ['SLACK_CHANNEL'],
        "text": text,
        "attachments": [
            {"color": "good",
            "fields": [
                { "title": "EC2 Instance", "value": instance_name, "short": "true"},
                { "title": "Expire Date", "value": expire_date, "short": "true"},
                { "title": "Total Snapshots Remaining", "value": snapshot_count, "short": "true"},
                ]
            }
            ]
    }
    
    response = requests.post(
        webhook_url, data=json.dumps(slack_data),
        headers={'Content-Type': 'application/json'}
    )
    if response.status_code != 200:
        raise ValueError(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
    )

def lambda_handler(event, context):
    account_ids = list()
    try:
        """
        You can replace this try/except by filling in `account_ids` yourself.
        Get your account ID with:
        > import boto3
        > iam = boto3.client('iam')
        > print iam.get_user()['User']['Arn'].split(':')[4]
        """
        account_ids.append(iam.get_user()['User']['Arn'].split(':')[4])
    except Exception as e:
        # use the exception message to get the account ID the function executes under
        account_ids.append(re.search(r'(arn:aws:sts::)([0-9]+)', str(e)).groups()[1])
    
    reservations = ec.describe_instances(
        Filters=[
            {'Name': 'tag-key', 'Values': ['backup', 'Backup']},
        ]
    ).get(
        'Reservations', []
    )
    instances = [
        i for r in reservations
        for i in r['Instances']
    ]
    
    print("Found %d instances that need backing up" % len(instances))
    
    to_tag = collections.defaultdict(list)
    
    for instance in instances:
        try:
            retention_days = [
                int(t.get('Value')) for t in instance['Tags']
                if t['Key'] == 'retention'][0]
        except IndexError:
            retention_days = 14
        
        for dev in instance['BlockDeviceMappings']:
            if dev.get('Ebs', None) is None:
                continue
            vol_id = dev['Ebs']['VolumeId']
            print("Found EBS volume %s on instance %s" % (
                vol_id, instance['InstanceId']))
            instance_name = [
                t.get('Value') for t in instance['Tags']
                if t['Key'] == 'Name'][0]
            snap = ec.create_snapshot(
                VolumeId=vol_id,
                Description=instance_name,
                TagSpecifications=[
                    {
                        'ResourceType': 'snapshot',
                        'Tags': [
                            {'Key': 'InstanceName','Value': instance_name}
                        ]
                    }
                ]
            )
            to_tag[retention_days].append(snap['SnapshotId'])
            
            status_msg = "Retaining snapshot %s of volume %s \nfrom instance '%s' for %d days" % (
                snap['SnapshotId'],
                vol_id,
                instance_name,
                retention_days,
            )
            print(status_msg)
            
            delete_date = datetime.date.today() + datetime.timedelta(days=retention_days)
            delete_fmt = delete_date.strftime('%Y-%m-%d')
            print("Will delete %d snapshots on %s" % (len(to_tag[retention_days]), delete_fmt))
            ec.create_tags(
                Resources=to_tag[retention_days],
                Tags=[
                    {'Key': 'DeleteOn', 'Value': delete_fmt},
                ]
            )
            instance_filter = [
                {'Name': 'tag-key', 'Values': ['InstanceName']},
                {'Name': 'tag-value', 'Values': [instance_name]},
            ]
            snapshot_count = len(ec.describe_snapshots(OwnerIds=account_ids, Filters=instance_filter)['Snapshots'])
            if 'snap' in locals():
                post_to_slack("Created snapshot %s" % snap['SnapshotId'], instance_name, snapshot_count, delete_fmt)
