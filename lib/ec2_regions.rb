module Ec2Regions
  def regions
    @regions ||= begin
      if cached?('regions')
        all_regions = read_cache('regions')
      else
        all_regions = ec2_client.describe_regions.to_hash.values.flatten
        write_cache('regions', all_regions)
      end
      all_regions
    end
  end

  def region_names
    @region_names ||= regions.map { |r| r[:region_name] }.sort
  end
end
