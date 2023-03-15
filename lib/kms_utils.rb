# frozen_string_literal: true

require 'aws-sdk-kms'
require_relative 'ec2/ec2_regions'
require_relative 'aws_utils/kms_key'

# to query AWS KMS keys
class KmsUtils < AwsUtils
  include Ec2Regions

  def kms_keys
    @kms_keys ||= begin
      if AwsUtils.cached?('kms_keys')
        all_kms_keys = AwsUtils.read_cache('kms_keys')
      else
        all_kms_keys = []
        region_names.each do |reg|
          kms_region_client = Aws::KMS::Client.new(region: reg)
          begin
            keys = kms_region_client.list_keys
          rescue Aws::KMS::Errors::AccessDeniedException
            next
          end
          next if keys[0].empty?

          keys[0].each do |key|
            region_key = kms_region_client.describe_key(key_id: key.key_id).key_metadata
            kms_key = KmsKey.new(region_key, reg, kms_region_client)
            all_kms_keys << kms_key
          end
          AwsUtils.write_cache('kms_keys', all_kms_keys.uniq)
        end
      end
      all_kms_keys.uniq
    end
  end

  def show_by_regions(filter = 'all')
    output_by_region(kms_keys, filter, keys_filter(filter), KMS_LEGEND)
  end

  def show_by_alias(alias_name)
    filtered_keys = kms_keys.select { |k| k.alias_names.join.include? alias_name }
    output_by_region(kms_keys, "'#{alias_name}'", filtered_keys, KMS_LEGEND)
  end

  def show_by_description(description)
    filtered_keys = kms_keys.select { |k| k.description.include? description }
    output_by_region(kms_keys, "'#{description}'", filtered_keys, KMS_LEGEND)
  end

  def show_by_region(region)
    raise "'region' must be one of #{region_names}".error unless region_names.include? region

    filtered_keys = kms_keys.select { |k| k.region == region }
    output_by_region(kms_keys, "'#{region}'", filtered_keys, KMS_LEGEND)
  end

  def audit
    subject = 'List of KMS keys with their status'
    audit_setup('kms_keys', subject)
    File.open(@curr_file, 'w') do |f|
      f.puts "### #{subject} #{@fdate} ###\n"
      yaml_output = {}
      kms_keys_used_regions.each do |region|
        keys_hash = {}
        kms_keys_by_region(region).each do |k|
          keys_hash[k.id] = { 'alias' => k.alias_names, 'key_rotation_enabled' => k.key_rotation }
        end
        yaml_output[region] = keys_hash
      end
      f.puts yaml_output.to_yaml.tr("'", '')
      f.puts "\n### #{subject} complete ###"
    end
    output_audit_report
  end

  private

  def keys_filter(filter)
    case filter
    when 'all'          then kms_keys
    when 'disabled'     then kms_keys.reject { |k| k.state == 'Enabled' }
    when 'enabled'      then kms_keys.select { |k| k.state == 'Enabled' }
    when 'non_rotating' then kms_keys.select { |k| k.key_rotation == false }
    end
  end

  def kms_keys_used_regions
    kms_keys.map(&:region).uniq.sort
  end

  def kms_keys_by_region(region)
    kms_keys.select { |key| key.region == region }.sort_by(&:id)
  end
end
