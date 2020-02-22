#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
info =  '  Green: encrypted'.light_green +
        '   Yellow: no logging'.light_yellow +
        '   Red: unencrypted'.light_red
puts info
puts DIVIDER
a = AwsUtils.new(cached?('s3buckets',msg=true))
a.s3buckets.each do |bucket|
  bucket.output_info
end
puts LINE
puts info
puts DIVIDER
puts 'Total S3 buckets: ' + a.s3buckets.count.to_s.yellow
