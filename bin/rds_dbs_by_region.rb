#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

a = AwsUtils.new(cached?('rdsdbs',msg=true) && cached?('regions',msg=true))
if ARGV[0] && ARGV[0] != 'all'
  regions = ARGV
else
  regions = a.region_names
end

regions.each do |region|
  reg_rdsdbs = a.rdsdbs_by_region(region)
  unless reg_rdsdbs.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Count: ' + reg_rdsdbs.count.to_s.yellow +
    '       Green: Available'.light_green + '   Red: Unavailable'.light_red
    puts DIVIDER
    reg_rdsdbs.sort_by { |rdsdb| rdsdb.name}.each do |reg_rdsdb|
      reg_rdsdb.output_object
    end
  end
end

if regions.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total RDS DB instances all regions: ' + a.rdsdbs.count.to_s.yellow
end

