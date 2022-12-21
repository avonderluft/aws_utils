# frozen_string_literal: true

require 'ec2_utils'
require 'ec2/ec2_volume'
aws_ec2 = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_ec2_instance.yaml"))
ec2_id = 'i-00000000000001'

RSpec.shared_examples 'a Ec2Utils object' do
  describe 'Ec2Instances' do
    describe '#ec2s' do
      it 'has ec2s' do
        expect(ec2u.ec2s).to be_an Array
        expect(ec2u.ec2s).to_not be_empty
      end
    end
  end

  describe '#show_by_id_or_name' do
    it { expect { ec2u.show_by_id_or_name(ec2_id) }.to output(/#{ec2_id}/).to_stdout }
    %w[id instance_type].each do |text|
      it { expect { ec2u.show_by_id_or_name(ec2_id) }.to output(/#{text}/).to_stdout }
    end
  end

  describe '#show_tags' do
    %w[Owner Team].each do |tag|
      it { expect { ec2u.show_tags }.to output(/#{tag}/).to_stdout }
    end
  end

  describe '#show_by_tag' do
    %w[Owner Team].each do |tag|
      it { expect { ec2u.show_by_tag(tag) }.to output(/#{ec2_id}/).to_stdout }
    end
  end
end

RSpec.describe Ec2Utils do
  context 'with caching' do
    subject(:ec2u) { described_class.new }
    it_behaves_like 'a Ec2Utils object'
  end

  context 'without caching' do
    subject(:ec2u) { described_class.new }

    before(:each) do
      allow(AwsUtils).to receive(:cached?).with('ec2s').and_return(false)
      ec2s_array = [Ec2Instance.new(aws_ec2, 'us-west-2')]
      allow_any_instance_of(Ec2Utils).to receive(:ec2s).and_return(ec2s_array)
    end

    it_behaves_like 'a Ec2Utils object'
  end
end

RSpec.describe Ec2Instance do
  aws_ec2 = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_ec2_instance.yaml"))
  subject(:ec2) { described_class.new(aws_ec2, 'us-west-2') }

  describe '#initialize' do
    it "has instance variable 'tags' populated" do
      expect(ec2.tags).to be_a Hash
      expect(ec2.tags).to_not be_empty
    end
  end

  describe '#tag_value' do
    %w[Team Owner].each do |tag|
      it "has tag '#{tag.downcase}' value matching the corresponding tag in AWS EC2 object" do
        expect(ec2.tag_value(aws_ec2, tag)).to eq ec2.tags[tag]
      end
    end
    it 'returns an empty string if the tag does not exist' do
      expect(ec2.tag_value(aws_ec2, 'not_a_tag')).to be_empty
    end
  end

  describe '#instance_uptime' do
    it 'returns hours time unit string based on launch time' do
      expect(ec2.instance_uptime(Time.parse('2017-04-03 20:59:01.000000000 Z'))).to match(/years/)
    end
    it 'returns seconds time unit string based on launch time' do
      expect(ec2.instance_uptime(Time.now)).to match(/secs/)
    end
  end

  describe '#status_color' do
    { running: 'light_green', stopped: 'yellow', terminated: 'light_red' }.each_pair do |state, color|
      context "when #{state}" do
        before { ec2.instance_variable_set(:@state, state.to_s) }
        it { expect(ec2.status_color).to eq color }
      end
    end
  end
end
