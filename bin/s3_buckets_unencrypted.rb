#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('s3buckets',msg=true))
a.s3buckets_unencrypted.each do |bucket|
  bucket.output_info
end
puts LINE
puts 'Total unencrypted S3 buckets: ' + a.s3buckets_unencrypted.count.to_s.yellow
