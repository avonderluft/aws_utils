#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users',msg=true))
puts "IAM users with no tag for email address".yellow
users = a.users_with_no_email
puts DIVIDER
users.each { |u| u.output_info }
puts LINE
puts 'Total IAM users with no tag for email address: ' + users.count.to_s.yellow

