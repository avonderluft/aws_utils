#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('ec2s', true) && cached?('regions', true))

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
    next if reg_ec2s.empty?

    puts 'Region: ' + region_name.light_cyan
    reg_ec2s.sort_by(&:name).each(&:output_info)
  end
end
if teams.count == 1
  puts LINE
else
  puts "\n" + LINE
  puts 'Total EC2 instances all regions: ' + a.ec2s.count.to_s.yellow
end
