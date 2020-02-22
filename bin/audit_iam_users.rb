#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon
include AuditCommon

setup('iam_users')
subject = 'List of IAM usernames and their active access keys'
print "Creating audit: #{subject}...".green

a = AwsUtils.new(cached?('users'))

open(@curr_file, 'a') do |f|
  f.puts "### #{subject} #{@fdate} ###\n\n"
  a.users.each do |user|
    user.keys.select{ |k| k[:status] == 'Active' }.each { |key| f.puts "#{user.name}: #{key[:id]}" }
  end
  f.puts "\n### #{subject} complete ###"
end

output_msg
