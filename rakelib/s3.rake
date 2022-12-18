# frozen_string_literal: true

require_relative '../lib/s3_utils'

desc 'Show info for specfic S3 bucket, by given bucket name'
task :s3, :name do |_t, args|
  check_cache
  S3Utils.new.show("name #{args[:name]}")
end

desc 'Show all S3 buckets'
task :s3s do
  check_cache
  S3Utils.new.show('all')
end

namespace :s3s do
  %w[encrypted unencrypted no_logging].each do |filter|
    desc "Show all #{filter} S3 buckets"
    task filter.to_sym do
      check_cache
      S3Utils.new.show(filter)
    end
  end
  desc 'Run audit for S3 buckets for encryption and logging'
  task :audit do
    puts `rake cache:clear`
    S3Utils.new.audit
  end
end
