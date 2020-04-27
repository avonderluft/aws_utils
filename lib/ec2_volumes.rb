# frozen_string_literal: true

require_relative 'ec2_volume'

module Ec2Volumes
  def volumes
    @volumes ||= begin
      if cached?('volumes')
        all_volumes = read_cache('volumes')
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
        end
        write_cache('volumes', all_volumes)
      end
      all_volumes
    end
  end

  def volume_owners
    volumes.map(&:owner).uniq.delete_if(&:empty?).sort
  end

  def volume_ec2_types
    volumes.map(&:ec2_type).uniq.delete_if(&:empty?).sort
  end

  def unencrypted_volumes
    volumes.select { |v| v.encrypted == false }
  end

  def unattached_volumes
    volumes.select { |v| v.ec2_name == '<none>' }
  end

  def unattached_unencrypted_volumes
    volumes.select { |v| v.ec2_name == '<none>' && v.encrypted == false }
  end

  def vols_by_region(region)
    volumes.select { |v| v.region == region }
  end

  def vols_by_ec2_type(ec2_type)
    volumes.select { |v| v.ec2_type == ec2_type }
  end

  def vol_tags
    volumes.map(&:tags)
  end
end
