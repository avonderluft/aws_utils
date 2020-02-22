#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon
include AuditCommon

setup('s3_buckets')
subject = 'List of S3 buckets with encryption and logging'
print "Creating audit: #{subject}...".green

a = AwsUtils.new(cached?('regions') && cached?('s3buckets'))

open(@curr_file, 'a') do |f|
  f.puts "### #{subject} #{@fdate} ###\n"
  yaml_output = {}
  a.s3buckets.each do |bucket|
    yaml_output[bucket.name] = { 'encryption' => bucket.encryption, 'logging' => bucket.logging }
    # bucket.keys.each { |key| f.puts "#{user.name}: #{key[:id]}" }
  end
  f.puts yaml_output.to_yaml
  f.puts "\n### #{subject} complete ###"
end

output_msg
