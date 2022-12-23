# frozen_string_literal: true

require 's3_utils'

RSpec.shared_examples 'an S3Utils object' do
  describe '#s3buckets' do
    it 'has buckets' do
      expect(s3utils.s3buckets).to be_an Array
      expect(s3utils.s3buckets).to_not be_empty
      expect(s3utils.s3buckets).to all be_a(S3Bucket)
    end
  end

  describe '#show' do
    %w[ID_Name Encryption].each do |text|
      it { expect { s3utils.show }.to output(/#{text}/).to_stdout }
    end
  end
end

RSpec.describe S3Utils do
  subject(:s3utils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'an S3Utils object'
  end

  context 'without caching' do
    pending 'need to set up fixtures and before block'
    it_behaves_like 'an S3Utils object'
  end
end
