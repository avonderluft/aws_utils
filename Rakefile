# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require_relative 'lib/aws_utils'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:style)

task default: :spec

def check_cache  
  puts `rake cache:clear` if ENV['cache'] == 'no'
end

namespace :audit do
  desc 'Run AWS audit for EC2 instances and their SSH keys'
  task :ec2 do
    puts `rake cache:clear`
    exec './bin/audit_ec2_instances.rb'
  end
  desc 'Run AWS audit for IAM users and their keys'
  task :iam do
    puts `rake cache:clear`
    exec './bin/audit_iam_users.rb'
  end
  desc 'Run AWS audit for KMS keys with their status'
  task :kms do
    puts `rake cache:clear`
    exec './bin/audit_kms_keys.rb'
  end
  desc 'Run AWS audit for S3 buckets for encryption and logging'
  task :s3 do
    puts `rake cache:clear`
    exec './bin/audit_s3_buckets.rb'
  end
  desc 'Run all AWS audits'
  task :all do
    %w[ec2 kms iam s3].each { |task| sh "rake audit:#{task}" }
  end
end

namespace :cache do
  desc 'Clear all cached objects'
  task :clear do
    cache_files = Dir.glob("#{File.dirname(__FILE__)}/cache/*")
    if cache_files.empty?
      puts "cache is already empty.".yellow
    else
      FileUtils.rm_rf cache_files
      cache_files.each do |cache_file|
        puts "#{cache_file} removed.".light_yellow
      end
    end
  end
  desc 'Show all cached objects'
  task :show do
    cache_files = Dir.glob("#{File.dirname(__FILE__)}/cache/*")
    cache_files.each do |cache_file|
      puts cache_file.green
    end
  end
end

desc 'Show info for EC2 instance by given id or name'
task :ec2, :ec2_id do |_t, args|
  check_cache
  exec "./bin/ec2s_by_name.rb #{args[:ec2_id]}"
end

desc 'Show all EC2 instances by Type, grouped by region'
task :ec2s do
  check_cache
  exec './bin/ec2s_by_type.rb'
end

namespace :ec2s do
  desc 'Show EC2 instances with no team owner set'
  task :no_team do
    check_cache
    exec './bin/ec2s_no_team.rb'
  end
  desc 'Show all EC2 instances by region, started within the last few days'
  task :new do
    check_cache
    exec './bin/ec2s_new.rb'
  end
  desc 'Show all large EC2 instances by region'
  task :large do
    check_cache
    exec './bin/ec2s_large.rb'
  end
  desc 'Show all running EC2 instances by region'
  task :running do
    check_cache
    exec './bin/ec2s_running_by_region.rb'
  end
  desc 'Show all stopped EC2 instances by region'
  task :stopped do
    check_cache
    exec './bin/ec2s_stopped_by_region.rb'
  end
  desc 'Show EC2 instances with their tags'
  task :tags do
    check_cache
    exec './bin/ec2_tags.rb'
  end
  desc 'Show EC2 instances for given Type, grouped by region'
  task :type, :type_value do  |_t, args|
    check_cache
    exec "./bin/ec2s_by_type.rb #{args[:type_value]}"
  end
  task :types, [:type_value] => :type
  desc 'Show EC2 instances for given region, or all EC2s by region'
  task :region, :region_value do  |_t, args|
    check_cache
    exec "./bin/ec2s_by_region.rb #{args[:region_value]}"
  end
  task :regions, [:region_value] => :region
end

namespace :kms do
  desc 'Show all KMS keys by region with rotation status'
  task :keys do
    check_cache
    exec './bin/kms_keys_by_region.rb'
  end
  desc 'Show all KMS keys by region with complete info'
  task :keys_full do
    check_cache
    exec './bin/kms_keys_by_region.rb full'
  end
end

desc 'Show RDS DB instances by region'
task :rds do
  check_cache
  exec './bin/rds_dbs_by_region.rb'
end

desc 'Show all AWS regions'
task :regions do
  check_cache
  exec './bin/regions.rb'
end

desc 'Show info for specfic S3 bucket, by given bucket name'
task :s3, :name do |_t, args|
  check_cache
  exec "./bin/s3_by_name.rb #{args[:name]}"
end

desc 'Show all S3 buckets'
task :s3s do
  exec './bin/s3_buckets.rb'
end

namespace :s3s do
  desc 'Show all S3 buckets which are not encrypted'
  task :unencrypted do
    check_cache
    exec './bin/s3_buckets_unencrypted.rb'
  end
  desc 'Show all S3 buckets with no logging'
  task :no_logging do
    check_cache
    exec './bin/s3_buckets_no_logging.rb'
  end
end

desc 'Show all snapshots by region, with encrypted status'
task :snapshots do
  check_cache
  exec './bin/snapshots_by_region.rb'
end

namespace :snapshots do
  desc 'Show all unencrypted EBS snapshots'
  task :unencrypted do
    check_cache
    exec './bin/snapshots_unencrypted.rb'
  end
end

desc 'Show info for specfic user, by given user_name'
task :user, :name do |_t, args|
  check_cache
  exec "./bin/user_by_name.rb #{args[:name]}"
end

desc 'Show all AWS users, with groups and policies'
task :users do
  exec './bin/users.rb'
end

namespace :users do
  desc 'Show all users in given group name'
  task :group, :group_name do |_t, args|
    check_cache
    exec "./bin/users_by_group.rb #{args[:group_name]}"
  end
  desc 'Show all service users'
  task :service do
    check_cache
    exec './bin/users_service.rb'
  end
  desc 'Show all users with no email tag set'
  task :no_email do
    check_cache
    exec './bin/users_with_no_email.rb'
  end
  desc 'Show all users with no MFA set'
  task :no_mfa do
    check_cache
    exec './bin/users_with_no_mfa.rb'
  end
  desc 'Show all users with stale access keys'
  task :stale_key do
    check_cache
    exec './bin/users_with_stale_keys.rb'
  end
end

desc 'Show all EC2 volumes by region, with encrypted status'
task :volumes do
  check_cache
  exec './bin/volumes_by_region.rb'
end

namespace :volumes do
  desc 'Show volumes for given EC2 Type, grouped by region'
  task :type, :type_value do  |_t, args|
    check_cache
    exec "./bin/volumes_by_ec2_type.rb #{args[:type_value]}"
  end
  task :types, [:type_value] => :type
  desc 'Show all unencrypted EBS volumes'
  task :unencrypted do
    check_cache
    exec './bin/volumes_unencrypted.rb'
  end
  desc 'Show all EBS volumes not attached to an EC2 instance'
  task :unattached do
    check_cache
    exec './bin/volumes_unattached.rb'
  end
  namespace :unattached do
    desc 'Show all unencrypted EBS volumes not attached to an EC2 instance'
    task :unencrypted do
      check_cache 
      exec './bin/volumes_unattached_unencrypted.rb'
    end
  end
end
