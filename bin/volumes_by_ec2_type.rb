#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('volumes',msg=true) && cached?('ec2s',msg=true) && cached?('regions',msg=true))

if ARGV[0] && ARGV[0] != 'all'
  ec2_types = [ARGV.join(' ')]
else
  ec2_types = a.volume_ec2_types
  ec2_types << ''
end

ec2_types.each do |type|
  output_type = type.empty? ? '<none>' : type
  vols = a.vols_by_ec2_type(type)
  puts ''
  unless vols.empty?
    info = 'EC2 Type: ' + output_type.light_magenta + '  Count: ' + vols.count.to_s.yellow 
    puts info
    puts LINE
    a.region_names.each do |region_name|
      reg_vols = vols.select { |e| e.region == region_name }
      unless reg_vols.empty?
        puts "Region: " + region_name.light_cyan
        reg_vols.each do |vol_ec2|
          vol_ec2.output_info
        end
      end
    end
    puts LINE
  end
end
puts 'Total volumes all regions: ' + a.volumes.count.to_s.yellow

