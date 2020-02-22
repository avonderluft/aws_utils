class RdsDbInstance
  attr_reader :id, :resource_id, :name, :region, :az, :engine, :endpoint, :port, :user,
              :encrypted, :kms_key, :ca_cert, :arn, :public, :size, :status
  def initialize(i,region_name)
    @id = i.db_instance_identifier
    @resource_id = i.dbi_resource_id
    @name = i.db_name
    @region = region_name
    @az = i.availability_zone
    @engine = "#{i.engine} #{i.engine_version}"
    @endpoint = i.endpoint.address
    @port = i.endpoint.port
    @user = i.master_username
    @encrypted = i.storage_encrypted
    @kms_key = i.kms_key_id
    @ca_cert = i.ca_certificate_identifier
    @arn = i.db_instance_arn
    @public = i.publicly_accessible
    @created = i.instance_create_time
    @size = i.db_instance_class
    @status = i.db_instance_status
  end

  def state_color
    case status
    when 'available' then 'light_green'
    else 'light_red'
    end
  end

  def output_info
    output = { Name: name, InstanceID: id, Size: size }
    ap output, indent: 1, multiline: false, color: {string: state_color}
  end

end
