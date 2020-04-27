#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users', true))
puts 'IAM users with stale access keys'.yellow
users = a.users_with_stale_keys
puts DIVIDER
users.each(&:output_info)
puts LINE
puts 'Total IAM users with stale access keys: ' + users.count.to_s.yellow
