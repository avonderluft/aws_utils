#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

if ARGV[0]
  name = ARGV[0]
else
  puts "S3 Bucket name is required: 'rake user[<bucket_name>]'".red
  exit
end

puts LINE
a = AwsUtils.new(cached?('s3s', true))
s3buckets = a.s3buckets_by_name(name)
s3buckets.each(&:output_object)
puts LINE
