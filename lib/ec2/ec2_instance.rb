# frozen_string_literal: true

# to contain data from an AWS EC2 instance
class Ec2Instance
  attr_reader :id, :name, :region, :az, :instance_type, :platform, :cores, :public_ip, :private_ip,
              :subnet, :vpc, :key_name, :launch_time, :ami, :sec_groups, :monitoring, :state,
              :uptime, :block_devices, :groups, :tags

  def initialize(ec2, region_name)
    @id = ec2.instance_id
    @name = tag_value(ec2, 'Name')
    @region = region_name
    @az = ec2.placement.availability_zone
    @instance_type = ec2.instance_type
    @platform = ec2.platform_details
    @cores = ec2.cpu_options['core_count'].to_s
    @public_ip = ec2.public_ip_address
    @private_ip = ec2.private_ip_address
    @subnet = ec2.subnet_id
    @vpc = ec2.vpc_id
    @key_name = ec2.key_name
    @launch_time = ec2.launch_time
    @ami = ec2.image_id
    @sec_groups = ec2.security_groups.map(&:group_name)
    @monitoring = ec2.monitoring.state
    @state = ec2.state.name
    @uptime = instance_uptime(launch_time)
    @block_devices = arrange_block_devices(ec2.block_device_mappings)
    tag_hash = {}
    ec2.tags.each { |t| tag_hash[t.key] = t.value unless t.key == 'Name' }
    @tags = tag_hash
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

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: state_color }
  end

  def state_color
    case state
    when 'running'    then 'light_green'
    when 'stopped'    then 'yellow'
    when 'terminated' then 'light_red'
    else
      'cyan'
    end
  end

  private

  def arrange_block_devices(device_mappings)
    block_devs = []
    device_mappings.each do |dm|
      block_devs << {
        name: dm.device_name,
        volume_id: dm.ebs.volume_id,
        status: dm.ebs.status,
        attach_time: dm.ebs.attach_time,
        delete_on_termination: dm.ebs.delete_on_termination
      }
    end
    block_devs
  end

  def summary
    { ID_Name: "#{id} - #{name}", Region_AZ: "#{region} (#{az})", Type: instance_type,
      State: "#{state} - up #{uptime}", Block_Devices: block_devices, Tags: tags }
  end
end
