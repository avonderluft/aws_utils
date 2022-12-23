# frozen_string_literal: true

require 'fileutils'
require 'warning'
require 'simplecov'
require 'aws_utils'

SimpleCov.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

def fixtures_dir
  @fixtures_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def aws_utils_object
  @aws_utils_object ||= YAML.unsafe_load(File.read("#{fixtures_dir}/aws_utils.yaml"))
end

def aws_service_error
  @aws_service_error ||= begin
    req_context = Seahorse::Client::RequestContext.new
    Aws::S3::Errors::ServerSideEncryptionConfigurationNotFoundError.new(req_context, 'a test error')
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = './tmp/rspec-examples.txt'
  config.filter_run_when_matching :focus
  config.formatter = ENV.fetch('CI', false) == 'true' ? :progress : :documentation
  config.order = :random
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.before(:example) do
    %i[cli_found? check_account_owner access_ok? check_region].each do |method|
      allow_any_instance_of(AwsUtils).to receive(method).and_return(true)
    end
    allow_any_instance_of(AwsUtils).to receive(:set_default_region).and_return('us-west-2')
    allow_any_instance_of(AwsUtils).to receive(:caller_hash).and_return(
      {
        'UserId' => 'ABC123ABC123ABC123ABC',
        'Account' => '777777777777',
        'Arn' => 'arn:aws:iam::777777777777:user/nobody'
      }
    )
    stub_const('CACHE_PATH', "#{fixtures_dir}/cache")
    FileUtils.cp Dir.glob("#{fixtures_dir}/*_cache.yaml"), "#{fixtures_dir}/cache/"
    allow(AwsUtils).to receive(:cached?).with(anything).and_return(true)
  end
end

Warning.ignore(%r{gems/(aws-sdk|colorize|awesome_print)})
