#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('rdsdbs', true) && cached?('regions', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_rdsdbs = a.rdsdbs_by_region(region)
  next if reg_rdsdbs.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan +
       '  Count: ' + reg_rdsdbs.count.to_s.yellow +
       '       Green: Available'.light_green +
       '   Red: Unavailable'.light_red
  puts DIVIDER
  reg_rdsdbs.sort_by(&:name).each(&:output_object)
end

if regions.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total RDS DB instances all regions: ' + a.rdsdbs.count.to_s.yellow
end
