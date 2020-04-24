################################
# Purge EC2 snapshots based on DeleteOn tag
#
# tested on AWS Lambda with Python 3.8
#
# Used in conjunction with create_snapshots.py which creates
# Snapshot of EC2 instances, setting a DeleteOn tag, based the
# retention days set in the 'retention' tag on the EC2 instance
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

"""
This function looks at *all* snapshots that have a "DeleteOn" tag containing
the current day formatted as YYYY-MM-DD. This function should be run at least
daily.
"""

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

  delete_on = datetime.date.today().strftime('%Y-%m-%d')
  filters = [
      {'Name': 'tag-key', 'Values': ['DeleteOn']},
      {'Name': 'tag-value', 'Values': [delete_on]},
  ]

  snapshot_response = ec.describe_snapshots(OwnerIds=account_ids, Filters=filters)

  for snap in snapshot_response['Snapshots']:
      print("Deleting snapshot %s" % snap['SnapshotId'])
      instance_name = [
              t.get('Value') for t in snap['Tags']
              if t['Key'] == 'InstanceName'][0]
      ec.delete_snapshot(SnapshotId=snap['SnapshotId'])
      delete_on = datetime.date.today().strftime('%Y-%m-%d')
      instance_filter = [
          {'Name': 'tag-key', 'Values': ['InstanceName']},
          {'Name': 'tag-value', 'Values': [instance_name]},
      ]
      snapshot_count = len(ec.describe_snapshots(OwnerIds=account_ids, Filters=instance_filter)['Snapshots'])
      post_to_slack("Deleted snapshot %s" % snap['SnapshotId'], instance_name, snapshot_count, delete_on)
