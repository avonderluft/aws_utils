# frozen_string_literal: true

def aws_s3_buckets
  @aws_s3_buckets ||= YAML.load(File.read("#{fixtures_dir}/aws_s3_buckets.yaml"))
end

def rules_object
  @rules_object ||= YAML.load(File.read("#{fixtures_dir}/aws_s3_rules.yaml"))
end

RSpec.describe S3Bucket do

  before(:each) do
    @s3_client_dbl = double('s3_client')
    enc_methods = 'get_bucket_encryption.server_side_encryption_configuration.rules'
    allow(@s3_client_dbl).to receive_message_chain(enc_methods).and_raise(aws_service_error)
    allow(@s3_client_dbl).to receive_message_chain('get_bucket_logging.logging_enabled').and_return(nil)
    allow(@s3_client_dbl).to receive_message_chain('get_bucket_lifecycle.rules').and_return(rules_object)
  end

  describe '#initialize' do
    subject { S3Bucket.new(aws_s3_buckets.first, 'us-west-2', @s3_client_dbl) }
    it { is_expected.to be_an_instance_of S3Bucket }
    it { is_expected.to have_attributes(rules: ['Do the thing(Enabled)', 'Do the other thing(Disabled)']) }
    it { is_expected.to have_attributes(encryption: {}) }
    it { is_expected.to have_attributes(logging: 'none') }
  end

  describe '#created_date' do
    subject { S3Bucket.new(aws_s3_buckets.first, 'us-west-2', @s3_client_dbl).created_date }
    it { is_expected.to eq '2020-02-28' }
  end

  describe '#encryption_output' do
    subject { S3Bucket.new(aws_s3_buckets.first, 'us-west-2', @s3_client_dbl).encryption_output }
    it { is_expected.to be_nil }
  end

  describe '#output_info' do
    it 'outputs info to stdout' do
      s3_bucket = S3Bucket.new(aws_s3_buckets.first, 'us-west-2', @s3_client_dbl)
      expect { s3_bucket.output_info }.to output(/Encryption/).to_stdout
    end
  end
end

shared_examples_for 'an S3 Buckets array' do
  describe 'attributes' do
    it { is_expected.to be_an Array }
    it { is_expected.to all be_an_instance_of S3Bucket }
  end
end

RSpec.describe S3Buckets do
  before(:each) do
    @aws_utils = AwsUtils.new
  end
  describe '#s3buckets' do
    context 'with caching' do
      before(:each) do
        FileUtils.cp "#{fixtures_dir}/s3buckets_cache.yaml", "#{fixtures_dir}/cache/"
        allow(@aws_utils).to receive(:cached?).with('s3buckets').and_return(true)
        @s3_buckets = @aws_utils.s3buckets
      end
      subject { @s3_buckets }
      it_behaves_like 'an S3 Buckets array'
    end
    context 'without caching' do
      before(:each) do
        allow(@aws_utils).to receive(:cached?).with('s3buckets').and_return(false)
        @s3_client_dbl = double('@aws_utils.s3_client')
        allow(@aws_utils).to receive(:s3_client).and_return(@s3_client_dbl)
        allow(@s3_client_dbl).to receive_message_chain('list_buckets.buckets').and_return(aws_s3_buckets)
        allow(@s3_client_dbl).to receive_message_chain(
          'get_bucket_location.location_constraint').and_return('us-west-2')
        enc_methods = 'get_bucket_encryption.server_side_encryption_configuration.rules'
        allow(@s3_client_dbl).to receive_message_chain(enc_methods).and_raise(aws_service_error)
        allow(@s3_client_dbl).to receive_message_chain('get_bucket_logging.logging_enabled').and_return(nil)
        allow(@s3_client_dbl).to receive_message_chain('get_bucket_lifecycle.rules').and_return(rules_object)
        @s3_buckets = @aws_utils.s3buckets
      end
      subject { @s3_buckets }
      it_behaves_like 'an S3 Buckets array'
    end
  end

  describe '#s3buckets_by_name' do
    name = 'test-1'
    subject { @aws_utils.s3buckets_by_name(name) }
    it_behaves_like 'an S3 Buckets array'
    it 'is a subset of all the S3 buckets' do
      expect(@aws_utils.s3buckets.map(&:id)).to include(*subject.map(&:id))
    end
    it { is_expected.to have_attributes(size: 1) }
    it 'has 1 element with the name of the argument' do
      expect(subject.map(&:name)).to all eq name
    end
  end
  describe '#s3buckets_unencrypted' do
    subject { @aws_utils.s3buckets_unencrypted }
    it_behaves_like 'an S3 Buckets array'
    it 'is a subset of all the S3 buckets' do
      expect(@aws_utils.s3buckets.map(&:id)).to include(*subject.map(&:id))
    end
    it 'has elements which are unencrypted' do
      expect(subject.map(&:encryption)).to all eq({})
    end
  end
  describe '#s3buckets_no_logging' do
    subject { @aws_utils.s3buckets_no_logging }
    it_behaves_like 'an S3 Buckets array'
    it 'is a subset of all the S3 buckets' do
      expect(@aws_utils.s3buckets.map(&:id)).to include(*subject.map(&:id))
    end
    it { is_expected.to have_attributes(size: 3) }
    it 'has elements which have no logging' do
      expect(subject.map(&:logging)).to all eq 'none'
    end
  end
end
