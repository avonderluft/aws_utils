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
      asgi = Struct.new(:name, :min_, :max_, :desired, :current, :last_refresh)
      asg_array = []
      asgs.each do |a|
        line = asgi.new(a.short_name, a.min, a.max, a.desired, a.instances.size, a.last_refresh_date.to_s[0, 10])
        asg_array << line
      end
      asg_array
    end
  end

  def refresh_instance(name, monitor = true)
    selected = asgs.select { |a| a.short_name == name }
    if selected.empty?
      logger.error "Auto-scaling group '#{name}' not found"
    else
      asg = selected.first
      logger.info "Starting instance refresh of #{asg.name}"
      resp = asg_client.start_instance_refresh(
        {
          auto_scaling_group_name: asg.name,
          desired_configuration: {
            launch_template: {
              launch_template_name: asg.launch_template_name,
              version: '$Latest'
            }
          },
          preferences: {
            instance_warmup: 300,
            min_healthy_percentage: 90,
            skip_matching: false # set to true for testing, false for live
          }
        }
      )
      if monitor
        start_time = Time.now
        refresh_id = resp.to_h[:instance_refresh_id]
        show_refresh_status(asg.name, refresh_id)
        duration = "#{((Time.now - start_time) / 60).round} minutes"
        logger.info "Instance refresh of #{asg.name} completed in #{duration}"
      else
        logger.info "Instance refresh of #{asg.name} launched"
        puts "For status of refresh, run 'rake asg[#{name}]'".direct
      end
    end
  rescue StandardError => e
    die_gracefully("Auto-refresh of '#{name}' failed", e)
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

  def show_refresh_status(asg_name, refresh_id)
    puts DIVIDER
    puts "Status updates for ASG instance refresh of #{asg_name}".status
    puts DIVIDER
    percentage = new_percentage = 0
    to_update = 1
    puts "#{Time.now} - Beginning refresh of #{asg_name} instances".status
    until percentage == 100 && to_update.zero?
      sleep 120
      resp = asg_client.describe_instance_refreshes({ auto_scaling_group_name: asg_name })
      refreshes = resp.to_h[:instance_refreshes]
      refreshes.select! { |r| r[:instance_refresh_id] == refresh_id }
      new_percentage = refreshes.first[:percentage_complete] if refreshes.first[:percentage_complete]
      to_update = refreshes.first[:instances_to_update]
      percentage = new_percentage if new_percentage > percentage
      puts "#{Time.now} - #{new_percentage}% complete, #{to_update} instance(s) to update".status
    end
    puts DIVIDER
  end
end
