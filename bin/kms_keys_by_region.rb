#!/usr/bin/env ruby

require_relative '../lib/aws_utils'
include AwsCommon
full = ARGV[0] == 'full'

puts LINE
info =  '  Green: key enabled'.light_green +
        '   Yellow: enabled, no key rotation'.light_yellow +
        '   Red: key disabled'.light_red
puts info
puts DIVIDER
a = AwsUtils.new(cached?('kms_keys',msg=true) && cached?('regions',msg=true))

a.region_names.each do |region|
  reg_keys = a.kms_keys_by_region(region)
  unless reg_keys.empty?
    puts LINE
    puts 'Region: ' + region.light_cyan + '  Count: ' + reg_keys.count.to_s.yellow +
    '       Green: key enabled'.light_green +
    '   Yellow: enabled, no key rotation'.light_yellow +
    '   Red: key disabled'.light_red
    puts DIVIDER
    reg_keys.each do |key|
      full ? key.output_object(key.status_color) : key.output_info(false)
    end
  end
end

puts LINE
puts 'Total KMS keys all regions: ' + a.kms_keys.count.to_s.yellow

