require_relative 'rds_db_instance'

module RdsDbInstances
  def rdsdbs
    @rdsdbs ||= begin
      if cached?('rdsdbs')
        all_rdsdbs = read_cache('rdsdbs')
      else
        all_rdsdbs = []
        region_names.each do |region_name|
          rds = Aws::RDS::Client.new(region: region_name)
          rds.describe_db_instances.db_instances.each do |i|
            instance = RdsDbInstance.new(i,region_name)
            all_rdsdbs << instance
          end
        end
        write_cache('rdsdbs', all_rdsdbs)
      end
      all_rdsdbs
    end
  end

  def rdsdbs_used_regions
    rdsdbs.map { |rdsdb| rdsdb.region }.uniq.sort
  end

  def rdsdbs_by_region(region)
    rdsdbs.select { |i| i.region == region }.sort_by { |e| e.id }
  end

end
