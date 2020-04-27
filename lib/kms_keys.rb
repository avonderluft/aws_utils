# frozen_string_literal: true

require_relative 'kms_key'

module KmsKeys
  def kms_keys
    @kms_keys ||= begin
      if cached?('kms_keys')
        all_kms_keys = read_cache('kms_keys')
      else
        all_kms_keys = []
        region_names.each do |region|
          kms_region_client = Aws::KMS::Client.new region: region
          kms_region_client.list_keys.keys.each do |key|
            region_key = kms_region_client.describe_key(key_id: key.key_id).key_metadata
            kms_key = KmsKey.new(region_key, region, kms_region_client)
            all_kms_keys << kms_key
          end
          write_cache('kms_keys', all_kms_keys)
        end
      end
      all_kms_keys
    end
  end

  def kms_keys_used_regions
    kms_keys.map(&:region).uniq.sort
  end

  def kms_keys_by_region(region)
    kms_keys.select { |key| key.region == region }.sort_by(&:id)
  end
end
