# frozen_string_literal: true

require 'aws-sdk-autoscaling'
require_relative 'aws_utils'
require_relative 'aws_utils/auto_scaling_group'

# to query and act upon AWS Auto-scaling groups
class AsgUtils < AwsUtils
  def asg_client
    @asg_client ||= Aws::AutoScaling::Client.new region: default_region
  end

  def asgs
    @asgs ||= begin
      if AwsUtils.cached?('auto_scaling_groups')
        all_asgs = AwsUtils.read_cache('auto_scaling_groups')
      else
        all_asgs = []
        region_names.each do |region_name|
          asg_reg_client = Aws::AutoScaling::Client.new region: region_name
          asg_reg_client.describe_auto_scaling_groups.auto_scaling_groups.each do |group|
            asg = AutoScalingGroup.new(group, region_name, asg_reg_client)
            all_asgs << asg
          end
        rescue Aws::AutoScaling::Errors::AccessDeniedException
          next
        end
        AwsUtils.write_cache('auto_scaling_groups', all_asgs)
      end
      all_asgs
    end
  end

  def asgs_table_array
    @asgs_table_array ||= begin
      asgi = Struct.new(:name, :min, :max, :desired, :current, :last_refresh)
      asg_array = []
      asgs.each do |a|
        line = asgi.new(a.short_name, a.min, a.max, a.desired, a.instances.size, a.last_refresh_date.to_s[0,10])
        asg_array << line
      end
      asg_array
    end
  end

  def refresh_instances(name)
    selected = asgs.select { |a| a.short_name == name }
    if selected.empty?
      logger.error "Auto-scaling group '#{name}' not found"
    else
      asg = selected.first
      logger.info "Starting instance refresh on #{asg.name}..."
      asg_client.start_instance_refresh({
        auto_scaling_group_name: asg.name,
        desired_configuration: {
          launch_template: {
            launch_template_name: asg.launch_template_name,
            version: "$Latest",
          },
        },
        preferences: {
          instance_warmup: 300,
          min_healthy_percentage: 90,
          skip_matching: false,
        },
      })
      puts "For status of instance refresh: 'rake asg[#{name}]'".direct
    end
  end

  def show_by_name(name)
    found_asgs = asgs.select { |i| i.short_name == name }
    puts LINE
    found_asgs.each { |asg| output_object(asg, asg.status_color) }
    if found_asgs.any?
      puts DIVIDER
      puts "For detail on an EC2 specify id e.g. 'rake ec2[#{found_asgs.first.instances.first}]'".direct
    else
      logger.error "Auto-scaling group '#{name}' not found"
    end
    # puts ASG_LEGEND
    puts LINE
  end

  def show_groups
    puts LINE
    # puts ASG_LEGEND
    asgs.each { |o| output_object(o, o.status_color) }
    puts LINE
    # puts ASG_LEGEND
    puts DIVIDER
    puts "Auto-scaling Groups: #{asgs.count.to_s.warning}"
  end

  def show_by_regions(filter = 'all')
    output_by_region(asgs, filter, asgs_filter(filter), ASG_LEGEND)
    puts asg_detail_instructions if asgs.any?
  end

  def asg_detail_instructions
    @asg_detail_instructions ||=
      "For detail on an ASG enter short name, e.g. 'rake asg[#{asgs.last.short_name}]'\n".direct +
      "To start instance refresh enter name, e.g. 'rake asg:refresh[#{asgs.last.short_name}]'\n".direct +
      DIVIDER + "\n" +
      "For detail on an EC2 specify id e.g. 'rake ec2[#{asgs.last.instances.last}]'\n".direct +
      DIVIDER
  end

  private

  def asgs_filter(filter)
    case filter
    when 'all' then asgs
    end
  end
end
