# frozen_string_literal: true

require_relative '../lib/user_utils'

me_desc = 'Show user info for me'
desc me_desc
task :whoami do
  check_cache
  uu = UserUtils.new
  uu.show_users_by_key_value('Name', uu.user_name)
end

desc 'Show info for specfic user, by given user_name'
task :user, :name do |_t, args|
  check_cache
  UserUtils.new.show_users_by_key_value('Name', args[:name])
end

namespace :user do
  desc me_desc
  task :me do
    check_cache
    uu = UserUtils.new
    uu.show_users_by_key_value('Name', uu.user_name)
  end
end

desc 'Show all AWS users, with groups and policies'
task :users do
  check_cache
  UserUtils.new.show_users_by('All')
end

namespace :users do
  desc 'Show all users in given group name'
  task :group, :group_name do |_t, args|
    check_cache
    UserUtils.new.show_users_by_key_value('Group', args[:group_name])
  end
  desc 'Show all service users'
  task :service do
    check_cache
    UserUtils.new.show_users_by('Service')
  end
  desc 'Show all users with no MFA set'
  task :no_mfa do
    check_cache
    UserUtils.new.show_users_by('No_MFA')
  end
  desc 'Show all users with stale access keys'
  task :stale_key do
    check_cache
    UserUtils.new.show_users_by('Stale_key')
  end
  desc 'Run audit for IAM users and their keys'
  task :audit do
    puts `rake cache:clear`
    UserUtils.new.audit
  end
  desc 'Show tabularized list of users with key expirations'
  task :table do
    check_cache
    uu = UserUtils.new
    info = { class: 'IAM Users with active keys', msg: uu.user_detail_instructions }
    options = :id, :name, { active_key: { width: 22 } }, :key_age, :days_left
    uu.table_print(uu.users_keys_expiry_table_array, options, info)
  end
end
