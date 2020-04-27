#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users', true))
puts 'IAM service user accounts'.yellow
users = a.service_users
puts DIVIDER
users.each(&:output_info)
puts LINE
puts 'Total IAM service user accounts: ' + users.count.to_s.yellow
