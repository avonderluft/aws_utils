# frozen_string_literal: true

require_relative '../lib/kms_utils'

desc 'Show all KMS keys by region with rotation status'
task :keys do
  check_cache
  KmsUtils.new.show_by_regions('all')
end

namespace :keys do
  %w[disabled enabled non_rotating].each do |filter|
    desc "Show all #{filter} KMS keys"
    task filter.to_sym do
      check_cache
      KmsUtils.new.show_by_regions(filter)
    end
  end

  desc 'Show all KMS keys including given alias name'
  task :name, :alias_name do |_t, args|
    check_cache
    KmsUtils.new.show_by_alias(args[:alias_name])
  end

  desc 'Show all KMS keys including given description'
  task :desc, :description do |_t, args|
    check_cache
    KmsUtils.new.show_by_description(args[:description])
  end

  desc 'Run audit for KMS keys with their status'
  task :audit do
    puts `rake cache:clear`
    KmsUtils.new.audit
  end
end
