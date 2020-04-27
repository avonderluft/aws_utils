#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('s3buckets', true))
a.s3buckets_unencrypted.each(&:output_info)
puts LINE
puts 'Total unencrypted S3 buckets: ' + a.s3buckets_unencrypted.count.to_s.yellow
