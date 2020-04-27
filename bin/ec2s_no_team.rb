#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('ec2s', true) && cached?('regions', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_ec2s = a.ec2s_by_region(region) & a.ec2s_no_team
  next if reg_ec2s.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan +
       '  Count: ' + reg_ec2s.count.to_s.yellow +
       '       Green: running'.light_green +
       '   Red: stopped'.light_red
  puts DIVIDER
  reg_ec2s.sort_by(&:name).each(&:output_no_team_info)
end

if regions.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total EC2 instances with no Team, all regions: ' + a.ec2s_no_team.count.to_s.yellow
end
