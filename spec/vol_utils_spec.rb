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
        %w[ID Attachments].each do |text|
          it { expect { volutils.show_by_regions(con) }.to output(/#{text}/).to_stdout }
          it { expect { volutils.show_by_regions(con) }.to output(/#{vol_id}/).to_stdout }
        end
      end
    end
    %w[unused unencrypted].each do |con|
      context con do
        it { expect { volutils.show_by_regions(con) }.to output(/#{con} Ec2Volumes:/).to_stdout }
        %w[ID Attachments].each do |text|
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
    regions = YAML.unsafe_load(File.read("#{fixtures_dir}/regions_cache.yaml"))

    before(:each) do
      allow(AwsUtils).to receive(:cached?).with('volumes').and_return(false)
      allow_any_instance_of(Ec2Volume).to receive(:regions).and_return(regions)
      vols_array = [Ec2Volume.new(aws_vol, 'us-west-2')]
      allow_any_instance_of(VolUtils).to receive(:volumes).and_return(vols_array)
    end

    it_behaves_like 'a volutils object'
  end
end

RSpec.describe Ec2Volume do
  subject(:vol) { described_class.new(aws_vol, 'us-west-2') }

  describe '#initialize' do
    it "has instance variable 'tags' populated" do
      expect(vol.tags).to be_a Hash
      expect(vol.tags).to_not be_empty
    end
    it "has instance variable 'attachments' populated" do
      expect(vol.attachments).to be_an Array
      expect(vol.attachments.first).to be_a Hash
      expect(vol.attachments.first[:ec2_id]).to eq ec2_id
    end
  end

  describe '#status_color' do
    { 'in-use': 'light_green', available: 'yellow' }.each_pair do |state, color|
      context "when #{state}" do
        before { vol.instance_variable_set(:@state, state.to_s) }
        it { expect(vol.status_color).to eq color }
      end
    end
  end

  describe '#output_summary' do
    %w[ID Region_AZ Tags].each do |label|
      it { expect { vol.output_summary }.to output(/#{label}/).to_stdout }
    end
  end
end
