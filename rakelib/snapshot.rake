# frozen_string_literal: true

require_relative '../lib/snap_utils'

snap_desc = 'Show all EC2 snapshots by region, with encrypted status'
desc snap_desc
task :snaps do
  check_cache
  SnapUtils.new.show_by_regions('all')
end
desc snap_desc
task snapshots: :snaps

namespace :snaps do
  %w[encrypted unencrypted].each do |filter|
    desc "Show all #{filter} snapshots"
    task filter.to_sym do
      check_cache
      SnapUtils.new.show_by_regions(filter)
    end
  end
end
