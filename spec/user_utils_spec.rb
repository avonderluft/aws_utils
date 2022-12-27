# frozen_string_literal: true

require 'user_utils'
aws_user = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_user.yaml"))
user_groups = %w[admin billing corporate]
user_tags = { email: 'me@example.com', dept: 'devops', level: 'senior' }

RSpec.shared_examples 'a UserUtils object' do
  describe '#users' do
    it 'has users' do
      expect(userutils.users).to be_an Array
      expect(userutils.users).to_not be_empty
      expect(userutils.users).to all be_an(IamUser)
    end
  end

  describe '#show_users_by' do
    %w[All No_MFA Stale_key].each do |filter|
      context "filter for #{filter}" do
        it { expect { userutils.show_users_by(filter) }.to output(/#{filter}/).to_stdout }
        it { expect { userutils.show_users_by(filter) }.to output(/IAMAUSERID4USER/).to_stdout }
      end
    end
  end

  describe '#show_users_by_key_value' do
    it 'returns a user by name' do
      expect do
        userutils.show_users_by_key_value('Name', userutils.user_name)
                 .to output(/Name: 'nobody'/).to_stdout
      end
    end
    it 'returns users by group' do
      expect do
        userutils.show_users_by_key_value('Group', 'billing')
                 .to output(/Group: 'billing'/).to_stdout
      end
    end
  end
end

RSpec.describe UserUtils do
  subject(:userutils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'a UserUtils object'
  end

  context 'without caching' do
    before do
      allow(AwsUtils).to receive(:cached?).with('users').and_return(false)
      iam_client = double('iam_client')
      allow_any_instance_of(IamUser).to receive(:mfa_enabled?).with(iam_client) { false }
      allow_any_instance_of(IamUser).to receive(:user_groups).with(iam_client) { user_groups }
      allow_any_instance_of(IamUser).to receive(:user_policies).with(iam_client) { [] }
      allow_any_instance_of(IamUser).to receive(:user_access_keys).with(iam_client) {
        [{ id: 'AAABBBCCCDDDEEEFFF', status: 'Active', age_days: '1044' }]
      }
      allow_any_instance_of(IamUser).to receive(:user_tags).with(iam_client) { user_tags }
      allow_any_instance_of(UserUtils).to receive(:users) { [IamUser.new(aws_user, iam_client)] }
    end

    it_behaves_like 'a UserUtils object'
  end
end
