# frozen_string_literal: true

require_relative '../lib/asg_utils'

desc 'Show details for an Auto-scaling Group by name'
task :asg, :name do |_t, args|
  AwsUtils.clear_cache
  AsgUtils.new.show_by_name(args[:name])
end

desc 'Show all Auto-scaling groups'
task :asgs do
  check_cache
  AsgUtils.new.show_by_regions('all')
end

namespace :asg do
  desc 'Refresh instances for an Auto-scaling Group by name'
  task :refresh, :name do |_t, args|
    check_cache
    AsgUtils.new.refresh_instances(args[:name])
  end
end

namespace :asgs do
  desc 'Show tabularized list of all Auto-scaling Groups'
  task :table do
    check_cache
    asgu = AsgUtils.new
    info = { class: 'Auto-scaling groups', msg: asgu.asg_detail_instructions }
    options = {}
    asgu.table_print(asgu.asgs_table_array, options, info)
  end

end