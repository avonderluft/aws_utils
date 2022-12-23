# frozen_string_literal: true

require 'aws-sdk-ec2'
require_relative 'ec2_utils'
require_relative 'ec2/ec2_snapshot'

# collection of all EC2 snapshots
class SnapUtils < Ec2Utils
  def snapshots
    @snapshots ||= begin
      if AwsUtils.cached?('snapshots')
        all_snapshots = AwsUtils.read_cache('snapshots')
      else
        all_snapshots = []
        snapshots =  ec2_client.describe_snapshots owner_ids: [owner_id]
        region_names.each do |region_name|
          ec2 = Aws::EC2::Resource.new(region: region_name)
          snapshots =  ec2.client.describe_snapshots owner_ids: [owner_id]
          snapshots[0].each do |snap|
            puts snap.to_yaml
            snapshot = Ec2Snapshot.new(snap, region_name)
            all_snapshots << snapshot
          end
        rescue Aws::EC2::Errors::UnauthorizedOperation
          next
        end
        AwsUtils.write_cache('snapshots', all_snapshots)
      end
      all_snapshots
    end
  end

  def show_by_regions(filter = 'all')
    output_by_region(snapshots, filter, snapshots_filter(filter), SNAP_LEGEND)
  end

  private

  def snapshots_filter(filter)
    case filter
    when 'all'         then snapshots
    when 'encrypted'   then snapshots.select { |s| s.encrypted == true }
    when 'unencrypted' then snapshots.select { |s| s.encrypted == false }
    when 'standard'    then snapshots.select { |s| s.storage_tier == 'standard' }
    when 'archived'    then snapshots.select { |s| s.storage_tier == 'archive' }
    end
  end
end
