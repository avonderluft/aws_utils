# frozen_string_literal: true

require 'user_utils'

RSpec.shared_examples 'a UserUtils object' do
  describe '#users' do
    it 'has users' do
      expect(userutils.users).to be_an Array
      expect(userutils.users).to_not be_empty
      expect(userutils.users).to all be_an(IamUser)
    end
  end

  describe '#show_users_by' do
    %w[All Service No_MFA Stale_key].each do |filter|
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
    pending 'need to set up fixtures and before block'
    it_behaves_like 'a UserUtils object'
  end
end
