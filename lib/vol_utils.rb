# frozen_string_literal: true

require 'aws-sdk-ec2'
require_relative 'ec2_utils'
require_relative 'ec2/ec2_volume'

# to query AWS EBS volumes
class VolUtils < Ec2Utils
  def volumes
    @volumes ||= begin
      if AwsUtils.cached?('volumes')
        all_volumes = AwsUtils.read_cache('volumes')
      else
        all_volumes = []
        region_names.each do |region_name|
          ec2 = Aws::EC2::Resource.new(region: region_name)
          ec2.client.describe_volumes.each do |page|
            page.volumes.each do |vol|
              volume = Ec2Volume.new(vol, region_name)
              all_volumes << volume
            end
          end
        rescue Aws::EC2::Errors::UnauthorizedOperation
          next
        end
        AwsUtils.write_cache('volumes', all_volumes)
      end
      all_volumes
    end
  end

  def show_by_id(id)
    puts LINE
    found_instances = volumes.select { |v| v.id == id }
    found_instances.each do |vol|
      output_object(vol, vol.status_color)
    end
    puts LINE
    puts ec2_detail_instructions
  end

  def show_by_regions(filter = 'all')
    output_by_region(volumes, filter, volumes_filter(filter), VOL_LEGEND)
    puts ec2_detail_instructions
  end

  private

  def volumes_filter(filter)
    case filter
    when 'all'         then volumes
    when 'unused'      then volumes.select { |v| v.state == 'available' }
    when 'encrypted'   then volumes.select { |v| v.encrypted == true }
    when 'used'        then volumes.select { |v| v.state == 'in-use' }
    when 'unencrypted' then volumes.select { |v| v.encrypted == false }
    when 'unattached'  then volumes.select { |v| v.ec2_name == '<none>' }
    end
  end
end
