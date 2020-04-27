#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../lib/aws_utils'
include AwsCommon

puts LINE
a = AwsUtils.new(cached?('regions', true))
a.regions.each do |region|
  puts 'Name: ' + region[:region_name].ljust(15).light_cyan +
       '  Endpoint: ' + region[:endpoint].yellow
end
puts LINE
