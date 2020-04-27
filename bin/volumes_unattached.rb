#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('volumes', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_vols = a.vols_by_region(region).select { |v| v.ec2_name == '<none>' }
  next if reg_vols.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan + '  Unattached Volume Count: ' + reg_vols.count.to_s.yellow
  puts DIVIDER
  reg_vols.each(&:output_unattached_info)
end

puts LINE
puts 'Total Unattached EBS Volumes all regions: ' + a.unattached_volumes.count.to_s.yellow unless regions.count == 1
