#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('snapshots',msg=true))
if ARGV[0] && ARGV[0] != 'all'
  regions = ARGV
else
  regions = a.region_names
end

regions.each do |region|
  reg_snaps = a.snapshots_by_region(region)
  unless reg_snaps.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Count: ' + reg_snaps.count.to_s.yellow +
    '       Green: encrypted'.light_green + '   Red: Unencrypted'.light_red
    puts DIVIDER
    reg_snaps.each do |reg_snap|
      reg_snap.output_info
    end
  end
end

puts LINE
puts 'Total EC2 Snapshots all regions: ' + a.snapshots.count.to_s.yellow unless regions.count == 1
