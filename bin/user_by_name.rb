#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  name = ARGV[0]
else
  puts "User name is required: 'rake user[<username>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('users', true))
users = a.user_by_name(name)
users.each(&:output_object)
puts LINE
