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
  reg_vols = reg_vols.select { |v| v.encrypted == false }
  unless reg_vols.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Unattached Unencrypted Volume Count: ' + reg_vols.count.to_s.yellow
    puts DIVIDER
    reg_vols.each do |reg_vol|
      reg_vol.output_unattached_unencrypted_info
    end
  end
end

puts LINE
unless regions.count == 1
  puts 'Total Unattached Unencrypted EBS Volumes all regions: ' + a.unattached_unencrypted_volumes.count.to_s.yellow 
end
