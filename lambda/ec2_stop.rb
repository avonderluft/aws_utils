##ruby 2
require 'json'
require 'aws-sdk-ec2'
require 'aws-sdk-sns'
require 'net/http'
require 'uri'
require 'openssl'

$region    = "us-west-2"
$instances = ['i-instance1', 'i-instance2']


# stop ec2 instances and creates an array instances_stopped of the instances it stopped
# region: the aws region to stop instances in   instances: an array of instance-ids to stop
def stop_ec2(region, instances)
  ec2 = Aws::EC2::Resource.new(region: region)
  @instances_stopped      = []
  @instances_stopped_name = []

  # perform for each instance-id provided in $instances array
  instances.each do |instance|
    instance      = ec2.instance(instance)
    instance_id   = instance.id
    instance_name = instance.tags.select{|tag| tag.key == "Name"}.first.value()

    if instance.exists?
      case instance.state.code
      when 48, 64, 80  # terminated, stopping, stopped
        puts "#{instance_name}:#{instance_id} is not running. Nothing to do."
      else
        instance.stop
        @instances_stopped << instance_id
        @instances_stopped_name << instance_name
      end
    end
  end

end

# send slack message using slackhook
# channel: the channel to post message, include the '#'   fallback:   region: the aws region to include in message   instances_stopped: array on stopped instance
def slack(channel, fallback, region, instances_stopped)
  uri = URI.parse('https://hooks.slack.com/services/<slack_token_here>')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true # set up SSL
  #http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Ignore the hostname mismatch SSL error

  # set POST and headers
  request = Net::HTTP::Post.new(uri.path, {"Content-Type": "application/json"})
  # set body
  payload = {
    "channel": channel,
    "attachments": [{
      "title": "Stopped Nodes",
      "fallback": fallback,
      "text": "One or more instances have been stopped",
      "color": "warning",
      "fields": [
        { "title": "Region", "value": region, "short": "true"},
        { "title": "Nodes", "value": "#{@instances_stopped_name.join("\n")}", "short": "true"},
      ]
    }]
  }

  request.body = payload.to_json
  response     = http.request(request)
  #puts request.body
  #puts response.body

  unless response.code.to_i == 200
    puts "[#{Time.now}]  ERROR: Response code from #{ur.host} was #{response.code}. Exiting."
    exit 1
  end
end

# formats message body to publish
# needs several arrays ## this is probably the most likely thing to fail
def format_body(region)
  @instances_stopped_padded      = []
  @instances_stopped_name_padded = []

  @instances_stopped.each do |instance|
    @instances_stopped_padded << instance.ljust(20, " ")
  end
  @instances_stopped_name.each do |instance|
    @instances_stopped_name_padded << instance.ljust(20, " ")
  end

  @body = "The following instances in the #{region} region were stopped:

  #{@instances_stopped_name_padded.join(' | ')}
  #{@instances_stopped_padded.join(' | ')}"
end

# publish a message to specified SNS arn
# arn: the aws arn of the sns resource to publish to   region: the aws region to stop instances in
def sns_publish(arn, region)
  sns   = Aws::SNS::Resource.new(region: region)
  topic = sns.topic(arn)

  topic.publish({
    topic_arn: "topicARN",
    subject: "AWS Lambda - Notice frrom the 'stop_ec2' function.",
    message: @body
  })
end

# does not need to be explicitly called. Not sure why, maybe this is what lambda is doing?
def lambda_handler(event:, context:)
  stop_ec2($region, $instances)
  if @instances_stopped.any? then # be careful with .any?, nil can be any
    puts "[#{Time.now}] The following instances in the " + $region + " region were stopped: "
    format_body($region) #formats message to be published
    sns_publish("arn:aws:sns:us-west-2:xxxxxxxxxx:ec2_stop", $region)
    slack("@backup.user", "fallback", $region, @instances_stopped)
  end
  #{ statusCode: 200, body: JSON.generate('Hello from Lambda!') }
end
