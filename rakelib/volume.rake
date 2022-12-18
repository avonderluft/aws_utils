# frozen_string_literal: true

require_relative '../lib/vol_utils'

vol_desc = 'Show all EC2 volumes by region, with encrypted status'
desc vol_desc
task :vols do
  check_cache
  VolUtils.new.show_by_regions('all')
end
desc vol_desc
task volumes: :vols

desc 'Show info for EBS volume by given id'
task :vol, :vol_id do |_t, args|
  check_cache
  VolUtils.new.show_by_id(args[:vol_id].to_s)
end

namespace :vols do
  %w[encrypted unencrypted used unused].each do |filter|
    desc "Show all #{filter} volumes"
    task filter.to_sym do
      check_cache
      VolUtils.new.show_by_regions(filter)
    end
  end
  task available: :unused
  task in_use: :used
end
