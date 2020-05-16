# frozen_string_literal: true

class Ec2Instance
  attr_reader :id, :region, :tags, :name, :type, :team, :owner, :public_ip, :private_ip,
              :key_name, :az, :launch_time, :uptime, :ami, :monitoring, :instance_type, :state,
              :sec_groups
  def initialize(ec2, region_name)
    @id = ec2.instance_id
    @region = region_name
    tag_hash = {}
    ec2.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
    @name = tag_value(ec2, 'Name')
    @type = tag_value(ec2, 'Type')
    @team = tag_value(ec2, 'Team')
    @owner = tag_value(ec2, 'Owner')
    @public_ip = ec2.public_ip_address
    @private_ip = ec2.private_ip_address
    @key_name = ec2.key_name
    @az = ec2.placement.availability_zone
    @launch_time = ec2.launch_time
    @ami = ec2.image_id
    @monitoring = ec2.monitoring.state
    @instance_type = ec2.instance_type
    @state = ec2.state.name
    @uptime = instance_uptime(launch_time)
    @sec_groups = ec2.security_groups.map(&:group_name)
  end

  def tag_value(ec2, tag_name)
    if ec2.tags.map(&:key).include?(tag_name)
      ec2.tags.select { |t| t.key == tag_name }.first.value
    else
      ''
    end
  end

  def instance_uptime(launch_time)
    return '' unless state == 'running'

    up_seconds = Time.now - launch_time
    return "#{up_seconds.round} secs" if up_seconds < 60

    up_minutes = up_seconds / 60
    return "#{up_minutes.round} mins" if up_minutes < 60

    up_hours = up_minutes / 60
    return "#{up_hours.round} hrs" if up_hours < 96

    up_days = up_hours / 24
    return "#{up_days.round} days" if up_days < 366

    up_years = up_days / 365.24
    "#{up_years.round(2)} years"
  end

  def state_color
    case state
    when 'running' then 'light_green'
    when 'stopped' then 'light_red'
    else 'yellow'
    end
  end

  def output_info
    output = { InstanceID: id, Name: name, Owner: owner, Team: team, Type: type,
               PublicIP: public_ip, PrivateIP: private_ip, Key: key_name,
               Size: instance_type, Uptime: uptime }
    ap output, indent: 1, multiline: true, color: { string: state_color }
  end

  def output_no_team_info
    output = { Name: name, PublicIP: public_ip, InstanceID: id, Owner: owner }
    ap output, indent: 1, multiline: false, color: { string: state_color }
  end
end
