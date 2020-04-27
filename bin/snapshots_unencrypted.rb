#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('snapshots', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_snaps = a.snapshots_by_region(region).select { |v| v.encrypted == false }
  next if reg_snaps.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan +
       '  Unencrypted Snapshot Count: ' + reg_snaps.count.to_s.yellow
  puts DIVIDER
  reg_snaps.each(&:output_info)
end

puts LINE
unless regions.count == 1
  puts 'Total Unencrypted EC2 Snapshots all regions: ' +
       a.unencrypted_snapshots.count.to_s.yellow
end
