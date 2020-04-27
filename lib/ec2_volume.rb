# frozen_string_literal: true

require_relative 'ec2_regions'
require_relative 'ec2_instances'

class Ec2Volume
  attr_reader :id, :region, :az, :instance_id, :ec2_name, :team, :owner, :ec2_type,
              :created, :encrypted, :kms_key, :size, :snapshot, :state, :type, :tags

  include Ec2Regions
  include Ec2Instances

  def initialize(vol, region_name)
    @id = vol.volume_id
    @region = region_name
    @az = vol.availability_zone
    @instance_id = vol.attachments.any? ? vol.attachments[0].instance_id : '<none>'
    @ec2_name = ec2_instance_name(instance_id)
    @team = ec2_instance_team(instance_id)
    @owner = ec2_instance_owner(instance_id)
    @ec2_type = ec2_instance_type(instance_id)
    @created = vol.create_time
    @encrypted = vol.encrypted
    @kms_key = vol.kms_key_id
    @size = vol.size
    @snapshot = vol.snapshot_id
    @state = vol.state
    @type = vol.volume_type
    tag_hash = {}
    vol.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
  end

  def ec2_instance_name(instance_id)
    instance_id == '<none>' ? '<none>' : ec2s_by_id(instance_id).first.name
  end

  def ec2_instance_team(instance_id)
    instance_id == '<none>' ? '<none>' : ec2s_by_id(instance_id).first.team
  end

  def ec2_instance_owner(instance_id)
    instance_id == '<none>' ? '<none>' : ec2s_by_id(instance_id).first.owner
  end

  def ec2_instance_type(instance_id)
    instance_id == '<none>' ? '<none>' : ec2s_by_id(instance_id).first.type
  end

  def encrypted_color
    encrypted ? 'light_green' : 'light_red'
  end

  def output_info
    output = { ID: id, EC2_Name: ec2_name, Team: team, Owner: owner, EC2_Type: ec2_type,
               Encrypted: encrypted, Type: type, State: state, Tags: tags }
    ap output, indent: 1, multiline: true, color: { string: encrypted_color }
  end

  def output_unencrypted_info
    output = { ID: id, EC2_Name: ec2_name, Team: team, Owner: owner }
    ap output, indent: 1, multiline: false, color: { string: encrypted_color }
  end

  def output_unattached_info
    output = { ID: id, Type: type, Encrypted: encrypted, Created: created,
               Size: size, State: state, Tags: tags }
    ap output, indent: 1, multiline: true, color: { string: encrypted_color }
  end

  def output_unattached_unencrypted_info
    output = { ID: id, Created: created, Size: size, Tags: tags }
    ap output, indent: 1, multiline: false, color: { string: encrypted_color }
  end
end
