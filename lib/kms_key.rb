# frozen_string_literal: true

class KmsKey
  attr_reader :id, :name, :region, :arn, :description, :created, :enabled, :key_rotation, :managed_by
  def initialize(key, region, kms_client)
    @id = key.key_id
    @name = kms_key_name(kms_client)
    @region = region
    @arn = key.arn
    @description = key.description
    @created = key.creation_date
    @enabled = key.enabled
    @key_rotation = kms_key_rotation_enabled(kms_client)
    @managed_by = key.key_manager
  end

  def kms_key_name(kms_client)
    aliases = kms_client.list_aliases(key_id: id).aliases
    return nil unless aliases.count.positive?

    aliases.first.alias_name.gsub('alias/', '')
  end

  def kms_key_rotation_enabled(kms_client)
    kms_client.get_key_rotation_status(key_id: id).key_rotation_enabled
  rescue Aws::KMS::Errors::ServiceError
    'unavailable'
  end

  def status_color
    if enabled
      key_rotation == true ? 'light_green' : 'light_yellow'
    else
      'light_red'
    end
  end

  def output_info(multiline = true)
    output = { ID: id, Name: name, Enabled: enabled, KeyRotation: key_rotation }
    ap output, indent: 1, multiline: multiline, index: false, color: { string: status_color }
  end
end
