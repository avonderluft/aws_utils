#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('volumes',msg=true))
if ARGV[0] && ARGV[0] != 'all'
  regions = ARGV
else
  regions = a.region_names
end

regions.each do |region|
  reg_vols = a.vols_by_region(region).select { |v| v.ec2_name == '<none>' }
  unless reg_vols.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Unattached Volume Count: ' + reg_vols.count.to_s.yellow
    puts DIVIDER
    reg_vols.each do |reg_vol|
      reg_vol.output_unattached_info
    end
  end
end

puts LINE
puts 'Total Unattached EBS Volumes all regions: ' + a.unattached_volumes.count.to_s.yellow unless regions.count == 1
