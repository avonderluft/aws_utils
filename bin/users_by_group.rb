#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  group = ARGV[0]
else
  puts "User name is required: 'rake user[<username>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('users', true))
users = a.users_by_group(group)
users.each(&:output_info)
puts LINE
