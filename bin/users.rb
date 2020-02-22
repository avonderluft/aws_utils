#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
info =  '  Green: MFA and email set'.light_green +
        '   Yellow: stale access key'.light_yellow +
        '   Red: No MFA and/or email'.light_red
puts info
puts DIVIDER
a = AwsUtils.new(cached?('users',msg=true))
a.users.each do |user|
  user.output_info
end
puts LINE
puts info
puts DIVIDER
puts 'Total IAM Users: ' + a.users.count.to_s.yellow
