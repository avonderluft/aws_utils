# frozen_string_literal: true

require 's3_utils'
aws_s3bucket = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_s3_bucket.yaml"))
aws_s3bucket_encryption = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_s3_bucket_encryption.yaml"))

RSpec.shared_examples 'an S3Utils object' do
  describe '#s3buckets' do
    it 'has buckets' do
      expect(s3utils.s3buckets).to be_an Array
      expect(s3utils.s3buckets).to_not be_empty
      expect(s3utils.s3buckets).to all be_a(S3Bucket)
    end
  end

  describe '#show_by_regions' do
    %w[ID Name Encryption].each do |text|
      it { expect { s3utils.show_by_regions('all') }.to output(/#{text}/).to_stdout }
    end
  end
end

RSpec.describe S3Utils do
  subject(:s3utils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'an S3Utils object'
  end

  context 'without caching' do
    before do
      allow(AwsUtils).to receive(:cached?).with('s3buckets').and_return(false)
      s3_client = double('s3_client')
      cli = double('cli')
      allow(s3_client).to receive(:get_bucket_encryption).and_return(aws_s3bucket_encryption)
      allow_any_instance_of(S3Bucket).to receive(:bucket_logging).with(s3_client).and_return('none')
      allow_any_instance_of(S3Bucket).to receive(:bucket_lifecycle_rules).with(s3_client).and_return([])
      allow_any_instance_of(S3Bucket).to receive(:bucket_tagging).and_return([])
      buckets_array = [S3Bucket.new(aws_s3bucket, 'us-west-2', s3_client, cli)]
      allow_any_instance_of(S3Utils).to receive(:s3buckets).and_return(buckets_array)
    end

    it_behaves_like 'an S3Utils object'
  end
end
