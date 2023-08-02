# frozen_string_literal: true

# to contain data from an AWS Auto-scaling group
class AutoScalingGroup
  attr_reader :name, :short_name, :region, :arn, :launch_template_id, :launch_template_name,
              :created, :min, :max, :desired, :instances, :status, :tags,
              :last_refresh, :last_refresh_date

  def initialize(group, region, asg_client)
    @name = group.auto_scaling_group_name
    @short_name = @name.sub(/-\d*$/, '')
    @region = region
    @arn = group.auto_scaling_group_arn
    @launch_template_id, @launch_template_name = fetch_launch_template(group.launch_template)
    @created = group.created_time
    @min = group.min_size
    @max = group.max_size
    @desired = group.desired_capacity
    @instances = group.instances.map(&:instance_id)
    @status = group.status
    @tags = fetch_tags(group.tags)
    refreshes = fetch_refreshes(asg_client)
    @last_refresh = refreshes.first if refreshes.any?
    @last_refresh_date = refreshes.any? ? (@last_refresh[:start_time] || @last_refresh[:end_time]) : 'none'
  end

  def status_color
    case status
    when 'ACTIVE', 'CREATING'              then 'light_green'
    when 'DELETING', 'UPDATING', 'PENDING' then 'yellow'
    when 'FAILED'                          then 'light_red'
    else
      'cyan'
    end
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def fetch_launch_template(group_lt)
    return nil, 'not found' unless group_lt

    [group_lt.launch_template_id, group_lt.launch_template_name]
  end

  def fetch_tags(group_tags)
    tags_hash = {}
    return tags_hash if group_tags.empty?

    group_tags.each do |t|
      next unless t.key

      tags_hash[t.key] = t.value
    end
    tags_hash
  end

  def fetch_refreshes(client)
    refreshes = []
    resp = client.describe_instance_refreshes({ auto_scaling_group_name: name })
    resp.instance_refreshes.each do |r|
      refr_hash = {
        id: r.instance_refresh_id,
        start_time: r.start_time,
        end_time: r.end_time,
        status: r.status,
        percent_complete: r.percentage_complete,
        preferences: r.preferences
      }
      refreshes << refr_hash
    end
    refreshes
  end

  def summary
    { Name: short_name, Full_Name: name,
      Launch_Template_ID: launch_template_id,
      Launch_Template_Name: launch_template_name,
      Min_Max_Desired: "#{min} / #{max} / #{desired}",
      Instances: instances, Status: status, Tags: tags,
      Last_Refresh_Date: last_refresh_date }
  end
end
