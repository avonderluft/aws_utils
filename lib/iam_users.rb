# frozen_string_literal: true

require_relative 'iam_user'

module IamUsers
  def users
    @users ||= begin
      if cached?('users')
        all_users = read_cache('users')
      else
        all_users = []
        iam_client.list_users.users.each do |iam_user|
          user = IamUser.new(iam_user, iam_client)
          all_users << user
        end
        write_cache('users', all_users)
      end
      all_users
    end
  end

  def user_by_name(name)
    users.select { |u| u.name == name }
  end

  def users_by_group(group)
    users.select { |u| u.groups.include? group }
  end

  def users_with_no_email
    users.select { |u| u.email.nil? }
  end

  def users_with_no_mfa
    users.select { |u| u.mfa == false }
  end

  def users_with_stale_keys
    users.select { |u| u.key_age.to_i > config['stale_key_days'] }
  end

  def service_users
    users.select { |u| u.name.start_with? 'svc_' }
  end
end
