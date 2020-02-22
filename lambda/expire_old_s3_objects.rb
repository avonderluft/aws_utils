require 'json'
require 'aws-sdk-s3'

$s3 = Aws::S3::Resource.new(region: ENV['REGION'])
$bucket = $s3.bucket(ENV['BUCKET'])

def slack(channel, expire_date, total_deleted)
  uri = URI.parse('https://hooks.slack.com/services/<slack_token_here>')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true # set up SSL
  #http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Ignore the hostname mismatch SSL error

  request = Net::HTTP::Post.new(uri.path, {"Content-Type": "application/json"})
  payload = {
    "channel": channel,
    "attachments": [{
      "title": "S3 expiration",
      "text": "objects > #{ENV['EXPIRE_YEARS']} years old deleted from S3 #{ENV['BUCKET']} bucket",
      "color": "warning",
      "fields": [
        { "title": "Expire Date", "value": "#{expire_date}", "short": "true"},
        { "title": "S3 Objects deleted", "value": "#{total_deleted}", "short": "true"},
      ]
    }]
  }
  request.body = payload.to_json
  response     = http.request(request)

  unless response.code.to_i == 200
    puts "[#{Time.now}]  ERROR: Response code from #{ur.host} was #{response.code}. Exiting."
    exit 1
  end
end

def lambda_handler(event:, context:)
  header = {
    "S3 bucket" => ENV['BUCKET'],
    "operation" => "Expire objects > #{ENV['EXPIRE_YEARS']} years.",
    "methodology" => "object key name date prefix 'yyyy/mm/dd'",
  }
  results = { "summary" => "" }
  status = "OK"
  total_deleted = 0
  expire_date = (Time.now - 86400 * 365.3 * ENV['EXPIRE_YEARS'].to_i)
  begin
    date_to_expire = expire_date
    date_string = date_to_expire.strftime("%Y/%m/%d")
    objects = $bucket.objects( { prefix: date_string } )
    while objects.count > 0 || date_to_expire == expire_date
      objects_deleted = 0
      objects.each do |obj|
        obj.delete
        objects_deleted += 1
        total_deleted += 1
      end
      puts "#{date_string} - objects deleted: #{objects_deleted}"
      results[date_string] = "objects deleted: #{objects_deleted}"
      date_to_expire = date_to_expire - 86400 # 1 day earlier
      date_string = date_to_expire.strftime("%Y/%m/%d")
      objects = $bucket.objects( { prefix: date_string } )
    end
    results['summary'] = "#{total_deleted} objects deleted"
  rescue Aws::S3::Errors::ServiceError => e
    status = "Error"
    results['error'] = e.message
  ensure
    slack("#<slack_channel>", expire_date.strftime("%Y/%m/%d"), total_deleted) # if total_deleted > 0
    return { status: status, header: JSON.generate(header), body: JSON.generate(results) }
  end
end
