# frozen_string_literal: true

require 'aws_utils'
require 'ec2/ec2_instance'
require 'iam_user'
require 'lambda'
require 's3_bucket'

RSpec.describe AwsUtils do
  subject(:awsutils) { described_class.new }

  describe '.cache_file_path' do
    %w[ec2s lambdas s3buckets users].each do |cache|
      context "cacheing #{cache}" do
        it "returns the correct path to the #{cache} cache file" do
          cache_path = described_class.cache_file_path(cache)
          expect(cache_path).to eq "#{CACHE_PATH}/#{cache}_cache.yaml"
        end
      end
    end
  end

  describe '.read_cache' do
    %w[ec2s lambdas s3buckets users].each do |cache|
      context "reading #{cache} cache" do
        it "returns the #{cache} cached file" do
          read_cached_file = described_class.read_cache(cache)
          expect(read_cached_file).to be_an Array
          expect(read_cached_file).to_not be_empty
          expect([Ec2Instance, Lambda, S3Bucket, IamUser])
            .to include read_cached_file.first.class
        end
      end
    end
  end

  describe '.clear_cache' do
    it 'has files cached beforehand' do
      cached_files = Dir.glob("#{CACHE_PATH}/*_cache.yaml")
      expect(cached_files.count).to be > 5
    end
    it 'removes all cached YAML files except regions' do
      described_class.clear_cache
      cached_files = Dir.glob("#{CACHE_PATH}/*_cache.yaml")
      expect(cached_files.count).to eq 1
    end
  end
end
