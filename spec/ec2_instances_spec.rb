# frozen_string_literal: true

RSpec.describe Ec2Instance do
  before(:each) do
    @aws_ec2 = YAML.load(File.read("#{fixtures_dir}/aws_ec2_instance.yaml"))
    @ec2 = Ec2Instance.new(@aws_ec2, 'us-west-2')
  end

  describe '#initialize' do
    subject { @ec2 }
    it { is_expected.to be_an_instance_of Ec2Instance }
    it do
      is_expected.to have_attributes(id: @aws_ec2.instance_id,
                                     region: 'us-west-2',
                                     public_ip: @aws_ec2.public_ip_address,
                                     private_ip: @aws_ec2.private_ip_address,
                                     key_name: @aws_ec2.key_name,
                                     launch_time: @aws_ec2.launch_time)
    end
    it do
      is_expected.to have_attributes(az: @aws_ec2.placement.availability_zone,
                                     ami: @aws_ec2.image_id,
                                     monitoring: @aws_ec2.monitoring.state,
                                     instance_type: @aws_ec2.instance_type,
                                     state: @aws_ec2.state.name,
                                     sec_groups: @aws_ec2.security_groups.map(&:group_name))
    end
  end

  describe '#tag_value' do
    %w[Name Type Team Owner].each do |tag|
      it "has '#{tag.downcase}' variable matching the corresponding tag in AWS EC2 object" do
        expect(@ec2.tag_value(@aws_ec2, tag)).to eq @ec2.send(tag.downcase)
      end
    end
    it 'returns an empty string if the tag does not exist' do
      expect(@ec2.tag_value(@aws_ec2, 'not_a_tag')).to be_empty
    end
  end

  describe '#instance_uptime' do
    it 'returns correct time unit string based on launch time' do
      expect(@ec2.instance_uptime(Time.parse('2017-04-03 20:59:01.000000000 Z'))).to match(/years/)
    end
  end

  describe '#state_color' do
    it 'outputs display color based on EC2 state' do
      case @ec2.state
      when 'running' then expect(@ec2.state_color).to eq 'light_green'
      when 'stopped' then expect(@ec2.state_color).to eq 'light_red'
      else expect(@ec2.state_color).to eq 'yellow'
      end
    end
  end
end

shared_examples_for 'an EC2 instances array' do
  describe 'attributes' do
    it { is_expected.to be_an Array }
    it { is_expected.to all be_an_instance_of Ec2Instance }
  end
end

RSpec.describe Ec2Instances do

  describe '#ec2s' do
    context 'with caching' do
      before(:each) do
        FileUtils.cp "#{fixtures_dir}/ec2s_cache.yaml", "#{fixtures_dir}/cache/"
        @aws_utils = AwsUtils.new
        allow(@aws_utils).to receive(:cached?).with('ec2s').and_return(true)
      end
      subject { @aws_utils.ec2s }
      it_behaves_like 'an EC2 instances array'
    end
    context 'without caching' do
      before(:each) do
        @aws_utils = AwsUtils.new
        allow(@aws_utils).to receive(:cached?).with('regions').and_return(true)
        allow(@aws_utils).to receive(:cached?).with('ec2s').and_return(false)
        allow(Aws::EC2::Resource).to_receive(:instances).and_return()
      end
    end
  end

  describe 'utility methods' do
    before(:each) do
      FileUtils.cp "#{fixtures_dir}/ec2s_cache.yaml", "#{fixtures_dir}/cache/"
      @aws_utils = AwsUtils.new
      allow(@aws_utils).to receive(:cached?).with('ec2s').and_return(true)
    end

    describe '#ec2_used_regions' do
      subject { @aws_utils.ec2_used_regions }
      it { is_expected.to be_an Array }
      it { is_expected.to include 'us-west-2' }
    end

    describe '#ec2_tags' do
      subject { @aws_utils.ec2_tags }
      it { is_expected.to be_an Array }
      it { is_expected.to all be_a Hash }
      %w[Name Owner Team Type].each do |tag_key|
        it "includes tag key #{tag_key}" do
          expect(subject.map(&:keys).flatten).to include tag_key
        end
      end
    end

    describe '#ec2_types' do
      subject { @aws_utils.ec2_types }
      it { is_expected.to be_an Array }
      it { is_expected.to all be_a String }
      %w[Testing demo smtp].each do |type|
        it { is_expected.to include type }
      end
    end

    describe '#ec2_teams' do
      subject { @aws_utils.ec2_teams }
      it { is_expected.to be_an Array }
      it { is_expected.to all be_a String }
      %w[Sales Security].each do |team|
        it { is_expected.to include team }
      end
    end

    describe 'slice methods' do

      %w[no_team running stopped new large].each do |slice|
        describe "#ec2s_#{slice}" do
          subject { @aws_utils.send("ec2s_#{slice}") }
          it_behaves_like 'an EC2 instances array'
        end
      end

      %w[region type name team id].each do |slice|
        describe "#ec2s_by_#{slice}" do
          subject { @aws_utils.send("ec2s_by_#{slice}",  @aws_utils.ec2s.first.send(slice)) }
          it_behaves_like 'an EC2 instances array'
        end
      end
    end

  end
end
