#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  id = ARGV[0]
else
  puts "Name or Id of EC2 is required: 'rake ec2[<name_or_id>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('ec2s',msg=true) && cached?('regions',msg=true))
found_instances = a.ec2s_by_name(id)
found_instances = a.ec2s_by_id(id) if found_instances.empty?
found_instances.each { |ec2| ec2.output_object(ec2.state_color) }
puts LINE
