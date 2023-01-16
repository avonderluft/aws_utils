# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require 'aws-sdk-ec2'
require 'awesome_print'
require 'colorize'
require 'diffy'
require 'fileutils'
require 'yaml'
require_relative 'audit_common'
require_relative 'constants'
require_relative 'ec2/ec2_regions'

# base class for querying AWS resources
class AwsUtils
  include AuditCommon
  include Ec2Regions

  attr_reader :cli, :default_region, :owner_id, :user_id, :user_name
  attr_accessor :ec2_client

  def self.cache_file_path(cache_name)
    "#{CACHE_PATH}/#{cache_name}_cache.yaml"
  end

  def self.cached?(cache_name, output: false)
    filepath = cache_file_path(cache_name)
    return false unless File.exist? filepath

    age_minutes = (Time.now - File.stat(filepath).mtime).to_i / 60
    mins_to_expire = if cache_name == 'regions_cache.yaml'
                       CONFIG['regions_cache_expire_minutes']
                     else
                       CONFIG['cache_expire_minutes'].to_i - age_minutes
                     end
    if mins_to_expire.negative?
      FileUtils.rm_f filepath
      puts "- expired '#{cache_name}' cache removed.".status
      false
    else
      if output
        filename = File.basename filepath
        puts " - Cache '#{filename}' expires in in #{mins_to_expire} minutes. 'rake cache:clear' to clear now.".info
        puts DIVIDER
      end
      true
    end
  end

  def self.write_cache(cache_name, content)
    File.write(cache_file_path(cache_name), YAML.dump(content))
  end

  def self.read_cache(cache_name)
    YAML.unsafe_load_file(cache_file_path(cache_name))
  end

  def self.clear_cache
    filenames = Dir.glob("#{CACHE_PATH}/*.yaml")
    filenames.delete_if { |fn| fn.include? 'regions_cache' } # keep regions cache file
    if filenames.empty?
      puts '- cache is already empty.'.status
    else
      FileUtils.rm_rf filenames
      filenames.each { |cache_file| puts "- #{cache_file} removed.".status }
    end
  end

  def initialize
    @cli = `command -v aws`.chomp
    exit unless cli_found?

    @default_region = set_default_region
    @ec2_client = Aws::EC2::Client.new region: default_region
    @user_id = caller_hash['UserId']
    @user_name = caller_hash['Arn'].split('/').last
    @owner_id = caller_hash['Account']
    Aws.use_bundled_cert!
    FileUtils.mkdir_p CACHE_PATH
    check_region
    check_account_owner # clear all caches if different account
    reset_mfa unless access_ok?
    puts "- #{self.class} object instantiated for '#{user_name}', ".status +
         "account '#{owner_id}' in region #{default_region}".status
  end

  def default_region=(region)
    raise "'region' must be one of #{region_names}".error unless region_names.include? region

    system "aws configure set region #{region}"
    puts "- default_region set to '#{region}'".status
    puts "Run 'rake regions' to see all available regions.".info
  end

  def output_object(object, status_color = 'light_green')
    output = output_hash(object)
    ap output, object_id: false, indent: -2, index: false, color: { string: status_color }
  end

  def output_by_region(full_set, filter, filtered_set, legend)
    region_show_count = 0
    region_names.each do |region|
      reg_items = full_set.select { |i| i.region == region } & filtered_set
      next if reg_items.empty?

      region_show_count += 1
      puts LINE
      region_summary = "Region: #{region.locale}  Count: #{reg_items.count.to_s.warning}"
      puts region_summary + legend
      reg_items.each(&:output_summary)
      puts DIVIDER + "\n#{region_summary}"
    end
    puts LINE
    descriptor = if full_set.count.positive?
                   "#{filter} #{full_set.first.class}s"
                 else
                   "#{Rake.application.top_level_tasks} items"
                 end
    puts "Total #{descriptor}: " + filtered_set.count.to_s.warning + legend
    puts DIVIDER
  end

  private

  def cli_found?
    if cli.empty?
      puts 'Ensure the AWS CLI is accessible in your PATH, e.g. add /opt/homebrew/bin'.error
      raise 'AWS CLI not found. Try running ./bin/setup.'.error
    else
      true
    end
  end

  def set_default_region
    `#{cli} configure get region --profile default`.chomp
  end

  def expired_token_msg(e)
    puts DIVIDER
    puts 'Your session is expired. Please reauthenticate'.warning
    puts DIVIDER
    puts e.message.error
    raise e
  end

  def caller_hash
    @caller_hash ||= JSON.parse(`aws sts get-caller-identity`)
  rescue JSON::ParserError => e
    expired_token_msg(e)
  end

  def check_region
    ec2_client.describe_internet_gateways
  rescue Aws::EC2::Errors::UnauthorizedOperation
    @ec2_client = Aws::EC2::Client.new region: 'us-east-1'
    system 'aws configure set region us-east-1'
    @default_region = 'us-east-1'
    puts "- Changed default region to 'us-east-1'".status
  rescue Aws::EC2::Errors::RequestExpired => e
    expired_token_msg(e)
  end

  def check_account_owner
    owner_id_file = "#{CACHE_PATH}/owner_id"
    FileUtils.touch owner_id_file
    return if owner_id == File.read(owner_id_file)

    File.write owner_id_file, owner_id
    puts "- Changed to new owner id '#{owner_id}'. Clearing the cache.".status
    cached_files = Dir.glob("#{CACHE_PATH}/*.yaml")
    FileUtils.rm_f cached_files
    cached_files.each { |file| puts "- #{file} removed.".status }
  end

  def access_ok?
    system "#{cli} ec2 --output text describe-internet-gateways &>/dev/null"
  end

  def reset_mfa
    puts 'Setting new MFA session...'.go
    if ENV['USER'].include? '.'
      first, last = ENV['USER'].split('.')
      aws_user = first[0] + last
    else
      aws_user = ENV['USER']
    end
    print "Enter AWS username (#{aws_user}): ".direct
    input = $stdin.gets.chomp
    aws_user = input unless input.empty?
    print 'Enter 6 digit MFA token: '.direct
    aws_token = $stdin.gets.chomp
    mfa_cmd = "#{File.join(File.dirname(__FILE__), '../bin/aws_mfa_set.sh')} -u #{aws_user} -t #{aws_token}"
    puts "Executing '#{mfa_cmd}'...".status
    print DIVIDER
    system mfa_cmd
    puts DIVIDER
  end

  def output_hash(obj)
    var_hash = {}
    obj.instance_variables.each do |var|
      next if obj.instance_of?(Ec2Volume) && %i[@regions @region_names @ec2s].include?(var)

      var_hash[var.to_s.delete('@')] = obj.instance_variable_get(var)
    end
    var_hash
  end
end
# rubocop:enable Metrics/ClassLength
