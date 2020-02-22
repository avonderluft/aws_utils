#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users',msg=true))
puts "IAM service user accounts".yellow
users = a.service_users
puts DIVIDER
users.each { |u| u.output_info }
puts LINE
puts 'Total IAM service user accounts: ' + users.count.to_s.yellow

