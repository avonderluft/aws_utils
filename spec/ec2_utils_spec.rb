# frozen_string_literal: true

require 'ec2_utils'
require 'ec2/ec2_volume'
# aws_ec2 = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_ec2_instance.yaml"))
ec2s_array = YAML.unsafe_load(File.read("#{fixtures_dir}/ec2_instances.yaml"))
ec2_id = 'i-00000000000001'

RSpec.shared_examples 'a Ec2Utils object' do
  describe 'Ec2Instances' do
    describe '#ec2s' do
      it 'has ec2s' do
        expect(ec2utils.ec2s).to be_an Array
        expect(ec2utils.ec2s).to_not be_empty
      end
    end
  end

  describe '#show_by_id_or_name' do
    it { expect { ec2utils.show_by_id_or_name(ec2_id) }.to output(/#{ec2_id}/).to_stdout }
    %w[id instance_type].each do |text|
      it { expect { ec2utils.show_by_id_or_name(ec2_id) }.to output(/#{text}/).to_stdout }
    end
  end

  describe '#show_tags' do
    %w[Owner Team].each do |tag|
      it { expect { ec2utils.show_tags }.to output(/#{tag}/).to_stdout }
    end
  end

  describe '#show_by_tag' do
    %w[Owner Team].each do |tag|
      it { expect { ec2utils.show_by_tag(tag) }.to output(/#{ec2_id}/).to_stdout }
    end
  end
end

RSpec.describe Ec2Utils do
  subject(:ec2utils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'a Ec2Utils object'
  end

  context 'without caching' do
    before do
      allow(AwsUtils).to receive(:cached?).with('ec2s').and_return(false)
      allow_any_instance_of(Ec2Utils).to receive(:ec2s).and_return(ec2s_array)
    end

    it_behaves_like 'a Ec2Utils object'
  end
end
