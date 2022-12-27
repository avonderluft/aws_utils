# frozen_string_literal: true

# to contain data from an AWS IAM user
class IamUser
  attr_reader :id, :name, :mfa, :arn, :created, :last_login, :groups, :policies,
              :keys, :tags, :svc_acct

  def initialize(user, iam_client)
    @id = user.user_id
    @name = user.user_name
    @mfa = mfa_enabled?(iam_client)
    @arn = user.arn
    @created = user.create_date.to_s.split.first
    @last_login = user.password_last_used
    @groups = user_groups(iam_client)
    @policies = user_policies(iam_client)
    @keys = user_access_keys(iam_client)
    @tags = user_tags(iam_client)
    @svc_acct = user.user_name.start_with? 'svc_'
  end

  def key_age
    return 'no keys!' if keys.empty?

    age = 0
    @key_age ||= begin
      keys.each do |key|
        next unless key[:status] == 'Active'

        key_age = key[:age_days]
        age = key_age if key_age.to_i > age.to_i
      end
      age
    end
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def summary
    { Name: name, ID: id, Created: created, Groups: groups, Policies: policies,
      MFA_enabled?: mfa, Keys: keys, LastLoginDays: last_login_days, Tags: tags }
  end

  def mfa_enabled?(iam_client)
    devices = iam_client.list_mfa_devices user_name: name
    devices.mfa_devices.any?
  end

  def last_login_date
    last_login.to_s.split.first
  end

  def last_login_days
    return 'none' if last_login.nil?

    ((Time.now - last_login) / 86_400).to_i.to_s
  end

  def user_groups(iam_client)
    @user_groups ||= begin
      group_list = iam_client.list_groups_for_user(user_name: name).groups
      group_list.map(&:group_name)
    end
  end

  def user_policies(iam_client)
    iam_client.list_user_policies(user_name: name).policy_names
  end

  def user_tags(iam_client)
    tags = {}
    iam_client.list_user_tags(user_name: name)[0].each do |tag|
      tags[tag.key] = tag.value
    end
    tags
  end

  def user_access_keys(iam_client)
    keys = []
    iam_client.list_access_keys(user_name: name).access_key_metadata.map.each do |key|
      age_in_days = ((Time.now - key.create_date) / 86_400).to_i
      keys << { id: key.access_key_id, status: key.status, age_days: age_in_days.to_s }
    end
    keys
  end

  def status_color
    if mfa == false
      'light_red'
    elsif key_age.to_i > CONFIG['stale_key_days'] || key_age == 'no keys!'
      'yellow'
    else
      'light_green'
    end
  end
end
