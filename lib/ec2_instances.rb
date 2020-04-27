# frozen_string_literal: true

require_relative 'ec2_instance'

module Ec2Instances
  def ec2s
    @ec2s ||= begin
      if cached?('ec2s')
        all_ec2s = read_cache('ec2s')
      else
        all_ec2s = []
        region_names.each do |region_name|
          ec2 = Aws::EC2::Resource.new(region: region_name)
          ec2.instances.each do |i|
            instance = Ec2Instance.new(i, region_name)
            all_ec2s << instance
          end
        end
        write_cache('ec2s', all_ec2s)
      end
      all_ec2s
    end
  end

  def ec2_used_regions
    ec2s.map(&:region).uniq.sort
  end

  def ec2_tags
    ec2s.map(&:tags)
  end

  def ec2_types
    ec2s.map(&:type).uniq.delete_if(&:empty?).sort
  end

  def ec2_teams
    ec2s.map(&:team).uniq.delete_if(&:empty?).sort
  end

  def ec2s_no_team
    ec2s.select { |i| i.team.empty? }
  end

  def ec2s_running
    ec2s.select { |i| i.state == 'running' }
  end

  def ec2s_stopped
    ec2s.select { |i| i.state == 'stopped' }
  end

  def ec2s_new
    ec2s_running.reject { |i| i.uptime =~ /(days|years)/ }
  end

  def ec2s_large
    ec2s_running.select { |i| i.instance_type.include? 'large' }
  end

  def ec2s_by_region(region)
    ec2s.select { |i| i.region == region }.sort_by(&:id)
  end

  def ec2s_by_type(type)
    ec2s.select { |i| i.type == type }
  end

  def ec2s_by_name(name)
    ec2s.select { |i| i.name == name }
  end

  def ec2s_by_team(team)
    ec2s.select { |i| i.team == team }
  end

  def ec2s_by_id(id)
    ec2s.select { |i| i.id.include? id }
  end
end
