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
  reg_vols = a.vols_by_region(region).select { |v| v.encrypted == false }
  unless reg_vols.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Unencrypted Volume Count: ' + reg_vols.count.to_s.yellow
    puts DIVIDER
    reg_vols.each do |reg_vol|
      reg_vol.output_unencrypted_info
    end
  end
end

puts LINE
puts 'Total Unencrypted EC2 Volumes all regions: ' + a.unencrypted_volumes.count.to_s.yellow unless regions.count == 1
