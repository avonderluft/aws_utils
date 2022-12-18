# frozen_string_literal: true

# to contain data from an AWS S3 Bucket
class S3Bucket
  attr_reader :id, :name, :created, :region, :encryption, :logging, :rules, :tags

  def initialize(bucket, region, s3_client)
    @id = bucket.object_id
    @name = bucket.name
    @created = bucket.creation_date
    @region = region
    @encryption = bucket_encryption(s3_client)
    @logging = bucket_logging(s3_client)
    @rules = bucket_lifecycle_rules(s3_client)
    @tags = bucket_tagging(s3_client)
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, index: false, color: { string: status_color }
  end

  private

  def bucket_encryption(s3_client)
    rules = s3_client.get_bucket_encryption(bucket: name).server_side_encryption_configuration.rules
    encrypt_hash = {}
    encrypt_hash['algorithm'] = rules.first.apply_server_side_encryption_by_default.sse_algorithm
    encrypt_hash['key'] = rules.first.apply_server_side_encryption_by_default.kms_master_key_id
    encrypt_hash
  rescue Aws::S3::Errors::ServerSideEncryptionConfigurationNotFoundError
    {}
  rescue StandardError => e
    puts e.message.warning
    {}
  end

  def bucket_logging(s3_client)
    logging_response = s3_client.get_bucket_logging(bucket: name).logging_enabled
    logging_response ? logging_response.target_bucket : 'none'
  rescue Aws::S3::Errors::PermanentRedirect => e
    puts e.message.warning
  end

  def bucket_tagging(s3_client)
    resp = s3_client.get_bucket_tagging(bucket: name)
    resp.tag_set.map { |t| "#{t.key}: #{t.value}" }
  rescue Aws::S3::Errors::NoSuchTagSet
    []
  rescue Aws::S3::Errors::PermanentRedirect => e
    puts e.message
    exit
  end

  def bucket_lifecycle_rules(s3_client)
    rules_array = []
    bucket_rules = s3_client.get_bucket_lifecycle(bucket: name).rules
    bucket_rules.each do |br|
      rules_array << "#{br.id} (#{br.status})"
    end
    rules_array
  rescue Aws::S3::Errors::NoSuchLifecycleConfiguration
    []
  rescue StandardError => e
    puts e.message.red
    []
  end

  def status_color
    if encryption.empty?
      'light_red'
    elsif logging == 'none'
      'yellow'
    else
      'light_green'
    end
  end

  def encryption_output
    if encryption.empty?
      nil
    else
      "#{encryption['algorithm']}: #{encryption['key']}"
    end
  end

  def summary
    display_region = region.empty? ? 'global' : region
    { ID_Name: "#{id} - #{name}", Created: created, Region: display_region,
      Encryption: encryption_output, Logging: logging, Rules: rules, Tags: tags }
  end
end
