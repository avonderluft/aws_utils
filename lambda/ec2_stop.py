
#python3

import json
import boto3
import datetime
import urllib.request
import urllib.parse

today = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
region = 'us-west-2'
# add more instances to control by comma separating instance ids
instances = ['i-instance1', 'i-instance2']
long_msg  = "The following instances in the " + region + " region were stopped: " + str(instances)
short_msg = "Stopped insances:" + str(instances)

# does not need to be explicitly callled: not sure why yet
def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)
    ec2.stop_instances(InstanceIds=instances)
    print(today + ' INFO: lamba_function stopped your instances: ' + str(instances))

# puts a message on specified SNS Topic
# sns_arn - the arn resource for the SNS topic   #msg the message to include
def sns_publish(sns_arn, msg):
    subject    = 'Lambda notice - The following instances were stopped: ' + str(instances)
    client     = boto3.client('sns')
    message    = {}
    email_body = msg
    sms_body   = short_msg #not using this now
    response = client.publish(
        TargetArn=sns_arn,
        MessageStructure='json',
        Subject=subject,
        Message=json.dumps({'default': json.dumps(message),
                            'sms': sms_body,
                            'email': email_body})
    )

# uses slack webhook to post message to slack
# user - user to submit as   channel - channel to submit to   msg - message to include
def slack_post(channel, fallback):
    url = 'https://hooks.slack.com/services/<slack_token_here>'
    payload = {
            "channel": channel,
            "attachments": [{
                "title": "Stopped Nodes",
                "fallback": fallback,
                "text": "One or more instances have been stopped",
                "color": "warning",
                "fields": [
                    { "title": "Region", "value": region, "short": "true"},
                    { "title": "Nodes", "value": "\n".join(instances), "short": "true"},
                    ]
                }]
            }
    headers = {
            "Content-Type": "application/json",
            "Accept": "*/*",
            }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data, headers)
    urllib.request.urlopen(req)

# go-to rooms: sre, sre_standup, wdp-shenanigans, deployments, lobster_quadrille
slack_post("#sre", long_msg)
sns_publish('arn:aws:sns:us-west-2:xxxxxxxxx:ec2_stop', long_msg)
