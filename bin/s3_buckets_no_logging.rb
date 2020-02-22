#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('s3buckets',msg=true))
a.s3buckets_no_logging.each do |bucket|
  bucket.output_info
end
puts LINE
puts 'Total S3 buckets with no logging: ' + a.s3buckets_no_logging.count.to_s.yellow
