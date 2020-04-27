#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('s3buckets', true))
a.s3buckets_no_logging.each(&:output_info)
puts LINE
puts 'Total S3 buckets with no logging: ' + a.s3buckets_no_logging.count.to_s.yellow
