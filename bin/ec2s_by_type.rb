#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('ec2s', true) && cached?('regions', true))

if ARGV[0] && ARGV[0] != 'all'
  types = [ARGV.join(' ')]
else
  types = a.ec2_types
  types << ''
end

types.each do |type|
  output_type = type.empty? ? '<none>' : type
  ec2s = a.ec2s_by_type(type)
  puts ''
  next if ec2s.empty?

  info = 'Type: ' + output_type.light_magenta +
         '  Count: ' + ec2s.count.to_s.yellow +
         '       Green: running'.light_green +
         '   Red: stopped'.light_red
  puts info
  puts LINE
  a.region_names.each do |region_name|
    reg_ec2s = ec2s.select { |e| e.region == region_name }
    unless reg_ec2s.empty?
      puts 'Region: ' + region_name.light_cyan
      reg_ec2s.sort_by(&:name).each(&:output_info)
    end
  end
  puts LINE
end
puts 'Total EC2 instances all regions: ' + a.ec2s.count.to_s.yellow
