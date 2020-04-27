# frozen_string_literal: true

require_relative 's3_bucket'

module S3Buckets
  def s3buckets
    @s3buckets ||= begin
      if cached?('s3buckets')
        all_s3buckets = read_cache('s3buckets')
      else
        all_s3buckets = []
        s3_client.list_buckets.buckets.each do |bucket|
          region = s3_client.get_bucket_location(bucket: bucket.name).location_constraint

          s3bucket = if region.empty? # this bucket has location in non-default region
                       loop_regions_for_bucket(bucket)
                     else
                       S3Bucket.new(bucket, region, s3_client)
                     end
          all_s3buckets << s3bucket
        end
        write_cache('s3buckets', all_s3buckets)
      end
      all_s3buckets
    end
  end

  def loop_regions_for_bucket(bucket)
    region_array = region_names.reverse             # US regions first!
    region_array.delete config['default_region']    # exclude the default, since that did not work
    # move 2nd default region to the top, since it is most likely to be the one that works
    region_array.insert(0, region_array.delete(config['second_default_region']))
    region_array.each do |region|
      alt_s3_client = Aws::S3::Client.new region: region
      begin
        alt_s3_client.head_bucket bucket: bucket.name
        return S3Bucket.new(bucket, region, alt_s3_client)
      rescue StandardError
        next
      end
    end
  end

  def s3buckets_by_name(name)
    s3buckets.select { |b| b.name == name }
  end

  def s3buckets_unencrypted
    s3buckets.select { |b| b.encryption.empty? }
  end

  def s3buckets_no_logging
    s3buckets.select { |b| b.logging == 'none' }
  end
end
