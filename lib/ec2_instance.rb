class Ec2Instance
  attr_reader :id, :region, :tags, :name, :type, :team, :owner, :public_ip, :private_ip,
              :key_name, :az, :launch_time, :uptime, :ami, :monitoring, :instance_type, :state, 
              :sec_groups
  def initialize(i,region_name)
    @id = i.id
    @region = region_name
    tag_hash = {}
    i.tags.each { |t| tag_hash[t.key] = t.value }
    @tags = tag_hash
    @name = i.tags.select { |t| t.key == 'Name' }.first.value rescue ''
    @type = i.tags.select { |t| t.key == 'Type' }.first.value rescue ''
    @team = i.tags.select { |t| t.key == 'Team' }.first.value rescue ''
    @owner = i.tags.select { |t| t.key == 'Owner' }.first.value rescue ''
    @public_ip = i.public_ip_address
    @private_ip = i.private_ip_address
    @key_name = i.key_name
    @az = i.placement.availability_zone
    @launch_time = i.launch_time
    @ami = i.image_id
    @monitoring = i.monitoring.state
    @instance_type = i.instance_type
    @state = i.state.name
    @uptime = instance_uptime(launch_time)
    @sec_groups = i.security_groups.map(&:group_name)
  end
  
  def instance_uptime(launch_time)
    return '' unless state == 'running'
    up_seconds = Time.now - launch_time
    return "#{up_seconds.round} secs" if up_seconds < 60
    up_minutes = up_seconds/60
    return "#{up_minutes.round} mins" if up_minutes < 60
    up_hours = up_minutes/60
    return "#{up_hours.round} hrs" if up_hours < 96
    up_days = up_hours/24
    return "#{up_days.round} days" if up_days < 366
    up_years = up_days/365.24
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
    output = {InstanceID: id, Name: name, Owner: owner, Team: team, Type: type,
               PublicIP: public_ip, PrivateIP: private_ip, Key: key_name,
               Size: instance_type, Uptime: uptime }
    ap output, indent: 1, multiline: true, color: {string: state_color}
  end
  
  def output_no_team_info
    output = { Name: name, PublicIP: public_ip, InstanceID: id, Owner: owner }
    ap output, indent: 1, multiline: false, color: {string: state_color}
  end

end
