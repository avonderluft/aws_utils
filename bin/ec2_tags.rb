#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('ec2s',msg=true) && cached?('regions',msg=true))
a.ec2s.each do |ec2|
  puts 'Tags for ' + ec2.id.cyan
  ap ec2.tags, index: false
end
puts LINE