# frozen_string_literal: true

require_relative 'ec2_instances'
require_relative 'ec2_regions'

# to contain data for an AWS EC2 instance
class Ec2Volume
  include Ec2Instances
  include Ec2Regions

  attr_reader :id, :region, :az, :created, :encrypted, :kms_key, :size, :snapshot, :state,
              :type, :tags, :attachments

  def initialize(vol, region_name)
    @id = vol.volume_id
    @region = region_name
    @az = vol.availability_zone
    @created = vol.create_time
    @encrypted = vol.encrypted
    @kms_key = vol.kms_key_id
    @size = "#{vol.size} gb"
    @snapshot = vol.snapshot_id
    @state = vol.state
    @type = vol.volume_type
    @attachments = volume_attachments(vol.attachments)
    tag_hash = {}
    vol.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
  end

  def status_color
    if encrypted && state == 'available'
      'yellow'
    else
      encrypted ? 'light_green' : 'light_red'
    end
  end

  def volume_attachments(vol_attachments)
    attach_array = []
    vol_attachments.each do |attachment|
      attach_array << {
        ec2_id: attachment.instance_id,
        ec2_name: ec2s_by_id(attachment.instance_id).first.name,
        ec2_type: ec2s_by_id(attachment.instance_id).first.instance_type
      }
    end
    attach_array
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def ec2_instance_type(instance_id)
    instance_id == '<none>' ? '<none>' : ec2s_by_id(instance_id).first.instance_type
  end

  def summary
    { ID: id, Region_AZ: "#{region} - #{az}", Size: size,
      Encrypted: encrypted, Type: type, State: state, Attachments: attachments, Tags: tags }
  end
end
