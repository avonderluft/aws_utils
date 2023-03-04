# frozen_string_literal: true

require_relative 'ec2_instance'

# collection of all the EC2 instance objects
module Ec2Instances
  def ec2s
    @ec2s ||= begin
      if AwsUtils.cached?('ec2s')
        all_ec2s = AwsUtils.read_cache('ec2s')
      else
        all_ec2s = []
        region_names.each do |region_name|
          ec2 = Aws::EC2::Resource.new(region: region_name)
          ec2.instances.each do |i|
            instance = Ec2Instance.new(i.data, region_name)
            all_ec2s << instance
          end
        rescue Aws::EC2::Errors::UnauthorizedOperation
          next
        end
        all_ec2s.sort_by! { |i| i.name }
        AwsUtils.write_cache('ec2s', all_ec2s)
      end
      all_ec2s
    end
  end

  def ec2s_table_array
    @ec2s_table_array ||= begin
      inst = Struct.new(:instance, :name, :state, :ami, :platform, :type, :ip_address)
      instances = []
      ec2s.each do |i|
        instances << inst.new(i.id, i.name, i.state,
                              i.ami, i.platform, i.instance_type, i.private_ip)
      end
      instances
    end
  end

  def ec2_used_regions
    ec2s.map(&:region).uniq.sort
  end

  def ec2_types
    ec2s.map(&:instance_type).uniq.sort
  end

  def ec2s_by_id(id)
    ec2s.select { |i| i.id.include? id }
  end

  def ec2s_by_region(region)
    ec2s.select { |i| i.region == region }.sort_by(&:id)
  end
end
