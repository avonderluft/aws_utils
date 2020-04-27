#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon
include AuditCommon

setup('kms_keys')
subject = 'List of KMS keys with their status'
print "Creating audit: #{subject}...".green

a = AwsUtils.new(cached?('kms_keys') && cached?('regions'))

File.open(@curr_file, 'a') do |f|
  f.puts "### #{subject} #{@fdate} ###\n"
  yaml_output = {}
  a.kms_keys_used_regions.each do |region|
    keys_hash = {}
    a.kms_keys_by_region(region).each do |k|
      keys_hash[k.id] = { 'alias' => k.name, 'key_rotation_enabled' => k.key_rotation }
    end
    yaml_output[region] = keys_hash
  end
  f.puts yaml_output.to_yaml.tr("'", '')
  f.puts "\n### #{subject} complete ###"
end

output_msg
