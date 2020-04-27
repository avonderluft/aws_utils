#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('ec2s', true) && cached?('regions', true))
a.ec2s.each do |ec2|
  puts 'Tags for ' + ec2.id.cyan
  ap ec2.tags, index: false
end
puts LINE
