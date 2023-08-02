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
  desc 'Launch and monitor instance refresh for ASG by name'
  task :refresh, :name do |_t, args|
    AsgUtils.new.refresh_instance(args[:name])
  end
  namespace :refresh do
    desc 'Launch instance refresh for ASG by name'
    task :launch_only, :name do |_t, args|
      # 2nd arg 'false' == do not monitor progress till completion
      AsgUtils.new.refresh_instance(args[:name], false)
    end
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
