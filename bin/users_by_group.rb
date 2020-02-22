#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  group = ARGV[0]
else
  puts "User name is required: 'rake user[<username>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('users',msg=true))
users = a.users_by_group(group)
users.each { |u| u.output_info }
puts LINE
