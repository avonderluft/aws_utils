#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('snapshots', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_snaps = a.snapshots_by_region(region)
  next if reg_snaps.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan +
       '  Count: ' + reg_snaps.count.to_s.yellow +
       '       Green: encrypted'.light_green +
       '   Red: Unencrypted'.light_red
  puts DIVIDER
  reg_snaps.each(&:output_info)
end

puts LINE
puts 'Total EC2 Snapshots all regions: ' + a.snapshots.count.to_s.yellow unless regions.count == 1
