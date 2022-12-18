# frozen_string_literal: true

# to contain data from an AWS EC2 snapshot
class Ec2Snapshot
  attr_reader :id, :owner_id, :owner_alias, :volume_id, :volume_size, :storage_tier,
              :region, :created, :encrypted, :kms_key, :state, :progress, :description, :tags

  def initialize(snap, region_name)
    @id = snap.snapshot_id
    @owner_id = snap.owner_id
    @owner_alias = snap.owner_alias
    @volume_id = snap.volume_id
    @volume_size = snap.volume_size
    @storage_tier = snap.storage_tier
    @region = region_name
    @created = snap.start_time
    @encrypted = snap.encrypted
    @kms_key = snap.kms_key_id
    @state = snap.state
    @progress = snap.progress
    @description = snap.description
    tag_hash = {}
    snap.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: encrypted_color }
  end

  private

  def encrypted_color
    encrypted ? 'light_green' : 'light_red'
  end

  def output_owner_alias
    owner_alias || '<none>'
  end

  def summary
    { ID: id, Vol_ID: volume_id, 'Owner ID/Alias': "#{owner_id} (#{output_owner_alias})",
      Vol_Size: "#{volume_size}gb", Storage_Tier: storage_tier, Desc: description,
      KMS_Key: kms_key, Created: created, Encrypted: encrypted, 'State/Progress': "#{state} #{progress}",
      Tags: tags }
  end
end
