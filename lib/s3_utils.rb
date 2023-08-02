# frozen_string_literal: true

require 'aws-sdk-s3'
require_relative 'aws_utils'
require_relative 'aws_utils/s3_bucket'

# to query AWS S3 buckets
class S3Utils < AwsUtils
  def s3_client
    @s3_client ||= Aws::S3::Client.new region: default_region
  end

  def s3buckets
    @s3buckets ||= begin
      if AwsUtils.cached?('s3buckets')
        all_s3buckets = AwsUtils.read_cache('s3buckets')
      else
        all_aws_buckets = s3_client.list_buckets.buckets
        all_s3buckets = []
        print " * Fetching #{all_aws_buckets.count} S3 buckets..".status
        s3_client.list_buckets.buckets.each do |bucket|
          s3bucket = create_bucket_object(bucket)
          all_s3buckets << s3bucket if s3bucket
          print '.'.status
        end
        puts '.done.'.status
      end
      AwsUtils.write_cache('s3buckets', all_s3buckets)
      all_s3buckets
    end
  end

  def s3s_table_array(filter = 'all')
    @s3s_table_array ||= begin
      buck = Struct.new(:id, :name, :created, :region, :objects, :bucket_size, :encryption)
      buckets = []
      s3s_filter(filter).each do |b|
        buckets << buck.new(b.id.to_s, b.name, b.created.to_s[0, 10], b.region,
                            b.objects, b.size, b.encryption['algorithm'])
      end
      buckets
    end
  end

  def show_by_id_or_name(id_or_name)
    puts LINE
    found_instances = s3buckets.select { |b| b.name == id_or_name }
    found_instances = s3buckets.select { |b| b.id.to_s.include? id_or_name } if found_instances.empty?
    found_instances.each { |bucket| output_object(bucket, bucket.status_color) }
    puts LINE
    puts S3_LEGEND
    puts LINE
  end

  def show_by_regions(filter = 'all')
    output_by_region(s3buckets, filter, s3s_filter(filter), S3_LEGEND)
    puts s3_detail_instructions if s3buckets.any?
  end

  def s3_detail_instructions
    @s3_detail_instructions ||=
      "For detail on a bucket: specify bucket id or name e.g. 'rake s3[#{s3buckets.last.id}]'\n".direct +
      DIVIDER
  end

  def audit
    subject = 'List of S3 buckets with encryption and logging'
    audit_setup('s3_buckets', subject)
    File.open(@curr_file, 'w') do |f|
      f.puts "### #{subject} #{@fdate} ###\n"
      yaml_output = {}
      s3buckets.each do |bucket|
        yaml_output[bucket.name] = { 'encryption' => bucket.encryption, 'logging' => bucket.logging }
      end
      f.puts yaml_output.to_yaml
      f.puts "\n### #{subject} complete ###"
    end
    output_audit_report
  end

  private

  def create_bucket_object(bucket)
    tries = 30
    retries ||= 0
    puts "Retry fetch of bucket #{bucket.name}...#{retries} of #{tries}".warning if retries.positive?
    suppress_output { s3_client.head_bucket(bucket: bucket.name) }
    loc_json = `#{cli} s3api get-bucket-location --bucket #{bucket.name}`
    loc_constraint = JSON.parse(loc_json)['LocationConstraint']
    bucket_region = loc_constraint.nil? ? default_region : loc_constraint
    if bucket_region == default_region
      S3Bucket.new(bucket, default_region, s3_client, cli)
    else
      S3Bucket.new(bucket, bucket_region, Aws::S3::Client.new(region: bucket_region), cli)
    end
  rescue Seahorse::Client::NetworkingError => e
    retry if (retries += 1) < tries + 1
    msg = 'Could not connect. May be network issues.'
    die_gracefully(msg, e)
  rescue Aws::S3::Errors::Forbidden
    puts ''
    logger.warn "Access to #{bucket.name} forbidden"
    nil
  end

  def s3s_filter(filter)
    case filter
    when 'all'         then s3buckets
    when 'empty'       then s3buckets.select { |b| b.objects == '0' }
    when 'encrypted'   then s3buckets.select { |b| b.encryption.any? }
    when 'no_logging'  then s3buckets.select { |b| b.logging == 'none' }
    when 'unencrypted' then s3buckets.select { |b| b.encryption.empty? }
    end
  end
end
