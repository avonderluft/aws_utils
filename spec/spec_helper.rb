# frozen_string_literal: true

require 'fileutils'
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'aws_utils'

def fixtures_dir
  @fixtures_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def aws_service_error
  @aws_service_error ||= begin
    req_context = Seahorse::Client::RequestContext.new
    Aws::S3::Errors::ServerSideEncryptionConfigurationNotFoundError.new(req_context, 'a test error')
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.before(:example) { FileUtils.cp "#{fixtures_dir}/regions_cache.yaml", "#{fixtures_dir}/cache/" }
end

module AwsSetup
  def mfa_set?
    true
  end
end

module AwsCommon
  def cli
    'testaws_bin'
  end

  def cache_file_path(cache_name)
    "#{File.join(File.dirname(__FILE__), 'fixtures/cache')}/#{cache_name}_cache.yaml"
  end
end
