#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('aws_lambdas', true))
regions = ARGV[0] && ARGV[0] != 'all' ? ARGV : a.region_names

regions.each do |region|
  reg_lambs = a.aws_lambdas_by_region(region)
  next if reg_lambs.empty?

  puts LINE
  puts 'Region: ' + region.light_cyan + '  Count: ' + reg_lambs.count.to_s.yellow
  puts DIVIDER
  reg_lambs.each(&:output_object)
end

puts LINE
puts 'Total Lambdas scripts all regions: ' + a.aws_lambdas.count.to_s.yellow unless regions.count == 1
