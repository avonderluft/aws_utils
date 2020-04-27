#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('volumes', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_vols = a.vols_by_region(region).select { |v| v.encrypted == false }
  next if reg_vols.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan + '  Unencrypted Volume Count: ' + reg_vols.count.to_s.yellow
  puts DIVIDER
  reg_vols.each(&:output_unencrypted_info)
end

puts LINE
puts 'Total Unencrypted EC2 Volumes all regions: ' + a.unencrypted_volumes.count.to_s.yellow unless regions.count == 1
