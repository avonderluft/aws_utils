# frozen_string_literal: true

require 'vol_utils'
aws_vol = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_ec2_volume.yaml"))
vol_id = 'vol-abcdef1234567890'
ec2_id = 'i-00000000000001'

RSpec.shared_examples 'a volutils object' do
  describe '#volumes' do
    it 'has volumes' do
      expect(volutils.volumes).to be_an Array
      expect(volutils.volumes).to_not be_empty
      expect(volutils.volumes).to all be_an(Ec2Volume)
    end
  end

  describe '#show_by_id' do
    %w[id kms_key].each do |text|
      it { expect { volutils.show_by_id(vol_id) }.to output(/#{text}/).to_stdout }
    end
    [vol_id, ec2_id].each do |id|
      it { expect { volutils.show_by_id(vol_id) }.to output(/#{id}/).to_stdout }
    end
  end

  describe '#show_by_regions' do
    %w[all encrypted].each do |con|
      context con do
        %w[ID Attachments ec2_device  delete_on].each do |text|
          it { expect { volutils.show_by_regions(con) }.to output(/#{text}/).to_stdout }
          it { expect { volutils.show_by_regions(con) }.to output(/#{vol_id}/).to_stdout }
        end
      end
    end
    %w[unused unencrypted].each do |con|
      context con do
        it { expect { volutils.show_by_regions(con) }.to output(/#{con} Ec2Volumes:/).to_stdout }
        %w[ID Attachments ec2_device delete_on].each do |text|
          it { expect { volutils.show_by_regions(con) }.to_not output(/#{text}/).to_stdout }
          it { expect { volutils.show_by_regions(con) }.to_not output(/#{vol_id}/).to_stdout }
        end
      end
    end
  end
end

RSpec.describe VolUtils do
  subject(:volutils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'a volutils object'
  end

  context 'without caching' do
    before do
      allow(AwsUtils).to receive(:cached?).with('volumes').and_return(false)
      vols_array = [Ec2Volume.new(aws_vol, 'us-west-2')]
      allow_any_instance_of(VolUtils).to receive(:volumes).and_return(vols_array)
    end

    it_behaves_like 'a volutils object'
  end
end

RSpec.describe Ec2Volume do
  subject(:volume) { described_class.new(aws_vol, 'us-west-2') }

  describe '#initialize' do
    it "has the attributes of an instance of #{described_class}" do
      expect(volume.tags).to be_a Hash
      expect(volume.tags).to_not be_empty
      expect(volume.attachments).to be_an Array
      expect(volume.attachments.first).to be_a Hash
      expect(volume.attachments.first[:ec2_id]).to eq ec2_id
    end
  end

  describe '#status_color' do
    { 'in-use': 'light_green', available: 'yellow' }.each_pair do |state, color|
      context "when #{state}" do
        before { volume.instance_variable_set(:@state, state.to_s) }
        it { expect(volume.status_color).to eq color }
      end
    end
  end

  describe '#output_summary' do
    %w[ID Region_AZ Tags].each do |label|
      it { expect { volume.output_summary }.to output(/#{label}/).to_stdout }
    end
  end
end
