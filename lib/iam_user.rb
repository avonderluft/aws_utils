# frozen_string_literal: true

# to contain data from an AWS IAM user
class IamUser
  attr_reader :id, :name, :mfa, :arn, :created, :last_login, :groups, :policies,
              :keys, :active_keys, :key_days_left, :tags, :svc_acct

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
    @active_keys = @keys.keep_if { |k| k[:status] == 'Active' }
    @key_days_left = days_till_key_expiry
    @tags = user_tags(iam_client)
    @svc_acct = user.user_name.start_with? 'svc_'
  end

  def key_age
    @key_age ||= begin
      return 'no keys!' if active_keys.empty?

      active_keys.first[:age_days]
    end
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def summary
    { Name: name, ID: id, Created: created, Groups: groups, Policies: policies,
      MFA_enabled?: mfa, Keys: keys, Key_Days_Left: key_days_left,
      LastLoginDays: last_login_days, Tags: tags }
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
    return keys if keys.empty?

    keys.sort_by { |k| k[:age_days].to_i }
  end

  def days_till_key_expiry
    return 'N/A' if active_keys.empty?

    "#{CONFIG['stale_key_days'].to_i - key_age.to_i}"
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
