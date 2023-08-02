# frozen_string_literal: true

require_relative '../lib/s3_utils'

desc 'Show details for S3 bucket by given id or name'
task :s3, :s3_id do |_t, args|
  check_cache
  S3Utils.new.show_by_id_or_name(args[:s3_id])
end

desc 'Show all accessible S3 buckets by regions'
task :s3s do
  check_cache
  S3Utils.new.show_by_regions('all')
end

namespace :s3s do
  desc 'Show tabularized list of all S3 buckets'
  task :table do
    check_cache
    s3u = S3Utils.new
    info = { class: 'S3 Buckets', msg: s3u.s3_detail_instructions }
    options = {}
    s3u.table_print(s3u.s3s_table_array, options, info)
  end

  %w[empty encrypted unencrypted no_logging].each do |filter|
    desc "Show all #{filter} S3 buckets"
    task filter.to_sym do
      check_cache
      S3Utils.new.show(filter)
    end
  end

  namespace :empty do
    desc 'Show tabularized list of all empty S3 buckets'
    task :table do
      check_cache
      s3u = S3Utils.new
      info = { class: 'Empty S3 Buckets', msg: s3u.s3_detail_instructions }
      options = {}
      s3u.table_print(s3u.s3s_table_array('empty'), options, info)
    end
  end

  desc 'Run audit for S3 buckets for encryption and logging'
  task :audit do
    puts `rake cache:clear`
    S3Utils.new.audit
  end
end
