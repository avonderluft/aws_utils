module AwsCommon

  LINE = '='.light_blue*108
  DIVIDER = '-'*88
  CACHE_PATH = File.join(File.dirname(__FILE__), '../cache')
  CLI = `command -v aws`.chomp
  
  def owner_id
    @owner_id ||= `#{CLI} sts get-caller-identity --output text --query Account`.chomp
  end

  def config
    @config ||= YAML.load(File.read("#{File.dirname(__FILE__)}/../config/config.yaml"))
  end
  
  def ce_client
    @ce_client ||= Aws::CostExplorer::Client.new region: config['default_region']
  end

  def ec2_client
    @ec2_client ||= Aws::EC2::Client.new region: config['default_region']
  end

  def iam_client
    @iam_client ||= Aws::IAM::Client.new region: config['default_region']
  end
  
  def rds_client
    @rds_client ||= Aws::RDS::Client.new region: config['default_region']
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new region: config['default_region']
  end

  def cache_file_path(cache_name)
     "#{CACHE_PATH}/#{cache_name}_cache.yaml"
  end

  def cached?(cache_name, output=false)
    filepath = cache_file_path(cache_name)
    return false unless File.exist? filepath
    age_minutes = (Time.now - File.stat(filepath).mtime).to_i / 60
    mins_to_expire = config['cache_expire_minutes'].to_i - age_minutes
    if mins_to_expire < 0
      FileUtils.rm_f filepath
      false
    else
      if output
        filename = File.basename filepath
        puts "Cache '#{filename}' expires in in #{mins_to_expire} minutes. 'rake cache:clear' to clear now."
        puts DIVIDER
      end
      true
    end
  end

  def write_cache(cache_name, content)
    File.open(cache_file_path(cache_name), 'w') { |f| f.write(YAML.dump(content)) }
  end

  def read_cache(cache_name)
    YAML.load(File.read(cache_file_path(cache_name)))
  end

  def output_hash(obj)
    hash = {}
    obj.instance_variables.each { |var| hash[var.to_s.delete('@')] = obj.instance_variable_get(var) }
    hash
  end

  def output_object(status_color='green')
    output = output_hash(self)
    ap output, object_id: false, indent: 1, index: false, color: {string: status_color}
  end
end
