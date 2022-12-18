# frozen_string_literal: true

# collection of all the accessible EC2 regions
module Ec2Regions
  def regions
    @regions ||= begin
      if AwsUtils.cached?('regions')
        all_regions = AwsUtils.read_cache('regions')
      else
        all_regions = ec2_client.describe_regions.to_hash.values.flatten
        if CONFIG['region_filters']
          filtered_regions = []
          CONFIG['region_filters'].each do |rf|
            filtered_regions.concat(all_regions.select { |r| r[:region_name].include? rf })
          end
          all_regions = filtered_regions
        end
        AwsUtils.write_cache('regions', all_regions)
      end
      all_regions
    end
  end

  def region_names
    @region_names ||= regions.map { |r| r[:region_name] }.sort
  end

  def show_regions
    puts LINE
    regions.each do |region|
      current = region[:region_name] == default_region
      name_label = 'Name: '
      endpoint_label = '  Endpoint: '
      if current
        name_label = name_label.caution
        endpoint_label = endpoint_label.caution
      end
      print name_label + region[:region_name].ljust(15).locale +
            endpoint_label + region[:endpoint].info
      puts current ? ' (current)'.caution : ''
    end
    puts LINE
    puts "To change default region: 'rake region[new_region]'".direct
    puts "To change region scope, update './config/config.yaml' then: 'rake regions cache=no'".direct
    puts DIVIDER
  end
end
