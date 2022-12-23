# frozen_string_literal: true

require 'snap_utils'
aws_snap = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_ec2_snapshot.yaml"))
snap_id = 'snap-00000000000000001'

RSpec.shared_examples 'a SnapUtils object' do
  describe '#snapshots' do
    it 'has snapshots' do
      expect(snaputils.snapshots).to be_an Array
      expect(snaputils.snapshots).to_not be_empty
      expect(snaputils.snapshots).to all be_an(Ec2Snapshot)
    end
  end

  describe '#show_by_regions' do
    %w[all encrypted standard].each do |filter|
      context filter do
        %w[ID Storage_Tier Encrypted].each do |text|
          it { expect { snaputils.show_by_regions(filter) }.to output(/#{text}/).to_stdout }
        end
      end
    end
  end
end

RSpec.describe SnapUtils do
  subject(:snaputils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'a SnapUtils object'
  end

  context 'without caching' do
    before(:each) do
      allow(AwsUtils).to receive(:cached?).with('snapshots').and_return(false)
      snaps_array = [Ec2Snapshot.new(aws_snap, 'us-west-2')]
      allow_any_instance_of(SnapUtils).to receive(:snapshots).and_return(snaps_array)
    end
    it_behaves_like 'a SnapUtils object'
  end
end

RSpec.describe Ec2Snapshot do
  subject(:ec2snap) { described_class.new(aws_snap, 'us-west-2') }

  describe '#initialize' do
    it 'has the attributes of an Ec2Snapshot object' do
      expect(ec2snap).to be_an(Ec2Snapshot)
      expect(ec2snap.id).to eq(snap_id)
      expect(ec2snap.volume_size).to be_an(Integer)
    end
    it "has instance variable 'tags' populated" do
      expect(ec2snap.tags).to be_a Hash
      expect(ec2snap.tags).to_not be_empty
    end
  end

  describe '#output_summary' do
    %w[ID Storage_Tier Encrypted].each do |label|
      it { expect { ec2snap.output_summary }.to output(/#{label}/).to_stdout }
    end
  end
end
