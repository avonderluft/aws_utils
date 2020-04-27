# frozen_string_literal: true

class Ec2Snapshot
  attr_reader :id, :region, :created, :encrypted, :kms_key, :volume_id, :state, :description, :tags

  def initialize(snap, region_name)
    @id = snap.snapshot_id
    @region = region_name
    @created = snap.start_time
    @encrypted = snap.encrypted
    @kms_key = snap.kms_key_id
    @volume_id = snap.volume_id
    @state = snap.state
    @description = abbreviated_description(snap.description)
    tag_hash = {}
    snap.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
  end

  def abbreviated_description(desc)
    desc.gsub!('Created by CreateImage', '')
    desc.gsub!('Copied for DestinationAmi ', '')
    desc.gsub!(" from #{volume_id}", '')
    desc.gsub!('SourceAmi ', '')
    desc.gsub!('SourceSnapshot ', '')
    desc.split('. Task created').first
  end

  def encrypted_color
    encrypted ? 'light_green' : 'light_red'
  end

  def output_info
    output = { ID: id, Vol_ID: volume_id, Desc: description, Created: created }
    ap output, indent: 1, multiline: false, color: { string: encrypted_color }
  end

  def output_unencrypted_info
    output = { ID: id, Desc: description, State: state, Tags: tags }
    ap output, indent: 1, multiline: true, color: { string: encrypted_color }
  end
end
