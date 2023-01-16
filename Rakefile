# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require_relative 'lib/ec2_utils'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:style)

task default: :spec

def check_cache
  puts `rake cache:clear` if ENV['cache'] == 'no'
end

namespace :cache do
  desc 'Clear cached objects'
  task :clear do
    AwsUtils.clear_cache
  end

  desc 'Show all cached objects'
  task :show do
    cache_files = Dir.glob("#{File.dirname(__FILE__)}/cache/*")
    cache_files.each do |cache_file|
      puts cache_file.info
    end
  end
end

namespace :audit do
  desc 'Run all AWS audit tasks'
  task :all do
    %w[ec2s keys users s3s].each { |task| sh "rake #{task}:audit" }
  end
end

desc 'Show filtered available AWS regions'
task :regions do
  FileUtils.rm_rf "#{CACHE_PATH}/regions_cache.yaml" if ENV['cache'] == 'no'
  Ec2Utils.new.show_regions
end

namespace :regions do
  desc 'Show all available AWS regions'
  task :all do
    Ec2Utils.new.show_regions(true)
  end
end

desc 'Set default region to arg: rake region[new_region]'
task :region, :region_value do |_t, args|
  ec2u = Ec2Utils.new
  ec2u.default_region = (args[:region_value])
end
