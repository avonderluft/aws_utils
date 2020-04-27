# frozen_string_literal: true

require_relative 'ec2_snapshot'

module Ec2Snapshots
  def snapshots
    @snapshots ||= begin
      if cached?('snapshots')
        all_snapshots = read_cache('snapshots')
      else
        all_snapshots = []
        region_names.each do |region_name|
          ec2 = Aws::EC2::Resource.new(region: region_name)
          snapshots =  ec2.client.describe_snapshots owner_ids: [owner_id]
          snapshots[0].each do |snap|
            snapshot = Ec2Snapshot.new(snap, region_name)
            all_snapshots << snapshot
          end
        end
        write_cache('snapshots', all_snapshots)
      end
      all_snapshots
    end
  end

  def unencrypted_snapshots
    snapshots.select { |s| s.encrypted == false }
  end

  def snapshots_by_region(region)
    snapshots.select { |s| s.region == region }
  end

  def snapshot_tags
    snapshots.map(&:tags)
  end
end
