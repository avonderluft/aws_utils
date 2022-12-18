# frozen_string_literal: true

require 'aws-sdk-s3'
require_relative 'aws_utils'
require_relative 's3_bucket'

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
        all_s3buckets = []
        s3_client.list_buckets.buckets.each do |bucket|
          s3region = s3_client.get_bucket_location(bucket: bucket.name).location_constraint
          s3region = default_region if s3region.empty?
          s3bucket = S3Bucket.new(bucket, s3region, Aws::S3::Client.new(region: s3region))
          all_s3buckets << s3bucket
        end
        AwsUtils.write_cache('s3buckets', all_s3buckets)
      end
      all_s3buckets
    end
  end

  def show(filter = 'all')
    s3sfil = filter[0, 5] == 'name ' ? s3buckets.select { |b| b.name == filter.split.last } : s3s_filter(filter)
    puts LINE
    puts S3_LEGEND
    s3sfil.each(&:output_summary)
    puts LINE
    puts "Total #{filter} S3 buckets: " + s3sfil.count.to_s.warning + S3_LEGEND
    puts DIVIDER
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

  def s3s_filter(filter)
    case filter
    when 'all'         then s3buckets
    when 'encrypted'   then s3buckets.select { |b| b.encryption.any? }
    when 'no_logging'  then s3buckets.select { |b| b.logging == 'none' }
    when 'unencrypted' then s3buckets.select { |b| b.encryption.empty? }
    end
  end
end
