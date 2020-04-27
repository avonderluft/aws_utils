# frozen_string_literal: true

class IamUser
  attr_reader :id, :name, :mfa, :arn, :created, :last_login,
              :groups, :policies, :keys, :tags, :svc_acct, :email
  def initialize(user, iam_client)
    @id = user.user_id
    @name = user.user_name
    @mfa = mfa_enabled?(iam_client)
    @arn = user.arn
    @created = user.create_date
    @last_login = user.password_last_used
    @groups = user_groups(iam_client)
    @policies = polices(iam_client)
    @keys = access_keys(iam_client)
    @tags = user_tags(iam_client)
    @svc_acct = user.user_name.start_with? 'svc_'
    @email = tags['email']
  end

  def group_list(iam_client)
    @group_list ||= iam_client.list_groups_for_user(user_name: name).groups
  end

  def mfa_enabled?(iam_client)
    devices = iam_client.list_mfa_devices user_name: name
    devices.mfa_devices.any?
  end

  def user_groups(iam_client)
    @user_groups ||= begin
      group_list = iam_client.list_groups_for_user(user_name: name).groups
      group_list.map(&:group_name)
    end
  end

  def last_login_date
    last_login.to_s.split.first
  end

  def last_login_days
    return 'none' if last_login.nil?

    ((Time.now - last_login) / 86_400).to_i.to_s
  end

  def user_tags(iam_client)
    tags = {}
    iam_client.list_user_tags(user_name: name)[0].each do |tag|
      tags[tag.key] = tag.value
    end
    tags
  end

  def polices(iam_client)
    iam_client.list_user_policies(user_name: name).policy_names
  end

  def access_keys(iam_client)
    keys = []
    iam_client.list_access_keys(user_name: name).access_key_metadata.map.each do |key|
      age_in_days = ((Time.now - key.create_date) / 86_400).to_i
      keys << { id: key.access_key_id, status: key.status, age_days: age_in_days.to_s }
    end
    keys
  end

  def key_age
    @key_age ||= begin
      age = '0'
      keys.each do |key|
        next unless key[:status] == 'Active'

        key_age = key[:age_days]
        age = key_age if key_age.to_i > age.to_i
      end
      age
    end
  end

  def tags_output
    tags_string = ''
    tags.each_pair { |key, value| tags_string << "#{key}: #{value}, " }
    tags_string.strip.chomp(',')
  end

  def status_color
    if email.nil? || mfa == false
      'light_red'
    elsif key_age.to_i > config['stale_key_days']
      'light_yellow'
    else
      'light_green'
    end
  end

  def output_info(multiline = true)
    output = { Name: name, Groups: groups.join(' '), Email: email, MFA_enabled?: mfa,
               KeyAgeDays: key_age, LastLoginDays: last_login_days, Tags: tags_output }
    ap output, indent: 1, multiline: multiline, index: false, color: { string: status_color }
  end
end
