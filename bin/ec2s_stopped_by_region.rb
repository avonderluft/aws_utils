#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('ec2s',msg=true) && cached?('regions',msg=true))
if ARGV[0] && ARGV[0] != 'all'
  regions = ARGV
else
  regions = a.region_names
end

regions.each do |region|
  reg_ec2s = a.ec2s_by_region(region).select { |ec2| ec2.state == 'stopped'}
  unless reg_ec2s.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Count: ' + reg_ec2s.count.to_s.yellow 
    puts DIVIDER
    reg_ec2s.sort_by { |ec2| ec2.name}.each do |reg_ec2|
      reg_ec2.output_info
    end
  end
end

if regions.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total stopped EC2 instances all regions: ' + a.ec2s_stopped.count.to_s.yellow
end

