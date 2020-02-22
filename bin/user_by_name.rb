#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  name = ARGV[0]
else
  puts "User name is required: 'rake user[<username>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('users',msg=true))
users = a.user_by_name(name)
users.each { |u| u.output_object }
puts LINE
