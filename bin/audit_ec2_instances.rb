#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon
include AuditCommon

setup('ec2_keys')
subject = 'List of EC2 instances and their SSH keys'
print "Creating audit: #{subject}...".green

a = AwsUtils.new(cached?('regions') && cached?('ec2s'))

open(@curr_file, 'a') do |f|
  f.puts "### #{subject} #{@fdate} ###\n"
  yaml_output = {}
  a.ec2_used_regions.each do |region|
    ec2s_hash = {}
    a.ec2s_by_region(region).each do |ec2|
      ec2s_hash[ec2.id]  = { 'name' => ec2.name, 'key' => ec2.key_name }
    end
    yaml_output[region] = ec2s_hash
  end
  f.puts yaml_output.to_yaml
  f.puts "\n### #{subject} complete ###"
end

output_msg
