# frozen_string_literal: true

class RdsDbInstance
  attr_reader :id, :resource_id, :name, :region, :az, :engine, :endpoint, :port, :user,
              :encrypted, :kms_key, :ca_cert, :arn, :public, :size, :status
  def initialize(rds, region_name)
    @id = rds.db_instance_identifier
    @resource_id = rds.dbi_resource_id
    @name = rds.db_name
    @region = region_name
    @az = rds.availability_zone
    @engine = "#{rds.engine} #{rds.engine_version}"
    @endpoint = rds.endpoint.address
    @port = rds.endpoint.port
    @user = rds.master_username
    @encrypted = rds.storage_encrypted
    @kms_key = rds.kms_key_id
    @ca_cert = rds.ca_certificate_identifier
    @arn = rds.db_instance_arn
    @public = rds.publicly_accessible
    @created = rds.instance_create_time
    @size = rds.db_instance_class
    @status = rds.db_instance_status
  end

  def state_color
    case status
    when 'available' then 'light_green'
    else 'light_red'
    end
  end

  def output_info
    output = { Name: name, InstanceID: id, Size: size }
    ap output, indent: 1, multiline: false, color: { string: state_color }
  end
end
