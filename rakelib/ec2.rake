# frozen_string_literal: true

require_relative '../lib/ec2_utils'

desc 'Show all EC2 instances by Type, grouped by region'
task :ec2s do
  check_cache
  Ec2Utils.new.show_by_regions('all')
end

desc 'Show details for EC2 instance by given id or name'
task :ec2, :ec2_id do |_t, args|
  check_cache
  Ec2Utils.new.show_by_id_or_name(args[:ec2_id])
end

namespace :ec2s do
  %w[large new running terminated stopped].each do |filter|
    desc "Show all #{filter} EC2 instances by region"
    task filter.to_sym do
      check_cache
      Ec2Utils.new.show_by_regions(filter)
    end
  end

  desc 'Show EC2 instances for given Tag, grouped by region'
  task :by_tag, :tag_value do |_t, args|
    check_cache
    Ec2Utils.new.show_by_tag(args[:tag_value])
  end

  desc 'Show EC2 instances with EKS cluster tags, grouped by region'
  task :eks_cluster do
    check_cache
    Ec2Utils.new.show_by_tag('aws:eks:cluster-name')
  end

  desc 'Show tabularized list of all EC2 instances'
  task :table do
    check_cache
    ec2u = Ec2Utils.new
    info = { class: 'EC2 instances', msg: ec2u.ec2_detail_instructions }
    options = :instance, { name: { width: 31 } }, { state: { width: 7 } },
              :ami, { platform: { width: 8 } }, :type, :ip_address
    ec2u.table_print(ec2u.ec2s_table_array, options, info)
  end

  desc 'Show tags for all EC2 instances'
  task :tags do
    check_cache
    Ec2Utils.new.show_tags
  end

  desc 'Show EC2 instances for given Type, grouped by region'
  task :type, :type_value do |_t, args|
    check_cache
    Ec2Utils.new.show_by_type(args[:type_value])
  end

  desc 'Show all available instance types, filtered by optional arg'
  task :types, :type_value do |_t, args|
    check_cache
    Ec2Utils.new.show_instance_types(args[:type_value])
  end

  desc 'Run audit for EC2 instances and their SSH keys'
  task :audit do
    puts `rake cache:clear`
    Ec2Utils.new.audit
  end
end
