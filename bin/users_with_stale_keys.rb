#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('users',msg=true))
puts "IAM users with stale access keys".yellow
users = a.users_with_stale_keys
puts DIVIDER
users.each { |u| u.output_info }
puts LINE
puts 'Total IAM users with stale access keys: ' + users.count.to_s.yellow

