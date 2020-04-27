#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users', true))
puts 'IAM users with no MFA set'.yellow
users = a.users_with_no_mfa
puts DIVIDER
users.each(&:output_info)
puts LINE
puts 'Total IAM users with MFA set: ' + users.count.to_s.yellow
