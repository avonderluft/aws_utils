# frozen_string_literal: true

# to contain data from an AWS KMS key
class KmsKey
  attr_reader :kms_client, :id, :alias_names, :region, :arn, :description, :usage,
              :created, :state, :key_rotation, :managed_by

  def initialize(key, region, kms_client)
    @id = key.key_id
    @alias_names = kms_alias_names(kms_client)
    @region = region
    @arn = key.arn
    @description = key.description
    @usage = key.key_usage
    @created = key.creation_date
    @state = key.deletion_date ? "#{key.key_state} on #{key.deletion_date}" : key.key_state
    @key_rotation = kms_key_rotation_enabled(kms_client)
    @managed_by = key.key_manager
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, index: false, color: { string: status_color }
  end

  private

  def kms_alias_names(kms_client)
    aliases = kms_client.list_aliases(key_id: id).aliases
    return [] unless aliases.count.positive?

    aliases.map(&:alias_name)
  end

  def kms_key_rotation_enabled(kms_client)
    kms_client.get_key_rotation_status(key_id: id).key_rotation_enabled
  rescue Aws::KMS::Errors::ServiceError
    false
  end

  def status_color
    if state == 'Enabled'
      key_rotation == true ? 'light_green' : 'yellow'
    else
      'light_red'
    end
  end

  def summary
    state
    { ID: id, Alias_Names: alias_names, ARN: arn, Desc: description, Usage: usage,
      Created: created, State: state,
      KeyRotation: key_rotation, Managed_by: managed_by }
  end
end
