#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('ec2s',msg=true) && cached?('regions',msg=true))

if ARGV[0] && ARGV[0] != 'all'
  teams = [ARGV.join(' ')]
else
  teams = a.ec2_teams
  teams << ''
end

teams.each do |team|
  output_team = team.empty? ? '<none>' : team
  ec2s = a.ec2s_by_team(team)
  info = 'Team: ' + output_team.light_magenta + '  Count: ' + ec2s.count.to_s.yellow +
  '       Green: running'.light_green + '   Red: stopped'.light_red
  puts ''
  puts info
  puts LINE
  a.region_names.each do |region_name|
    reg_ec2s = ec2s.select { |e| e.region == region_name }
    unless reg_ec2s.empty?
      puts 'Region: ' + region_name.light_cyan
      reg_ec2s.sort_by { |ec2| ec2.name}.each do |reg_ec2|
        reg_ec2.output_info
      end
    end
  end
end
if teams.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total EC2 instances all regions: ' + a.ec2s.count.to_s.yellow
end

