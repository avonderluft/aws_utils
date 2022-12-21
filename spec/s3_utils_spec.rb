# frozen_string_literal: true

require 's3_utils'
aws_bucket = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_s3_bucket.yaml"))
aws_logging = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_s3_bucket_logging.yaml"))

RSpec.shared_examples 'an S3Utils object' do
  describe '#s3buckets' do
    it 'has buckets' do
      expect(s3u.s3buckets).to be_an Array
      expect(s3u.s3buckets).to_not be_empty
    end
  end

  describe '#show' do
    %w[ID_Name Encryption].each do |text|
      it { expect { s3u.show }.to output(/#{text}/).to_stdout }
    end
  end
end

RSpec.describe S3Utils do
  context 'with caching' do
    subject(:s3u) { described_class.new }
    it_behaves_like 'an S3Utils object'
  end

  context 'without caching' do
    # TODO
  end
end
