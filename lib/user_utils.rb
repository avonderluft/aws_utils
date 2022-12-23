# frozen_string_literal: true

require 'aws-sdk-iam'
require_relative 'aws_utils'
require_relative 'iam_user'

# to query AWS IAM users
class UserUtils < AwsUtils
  def iam_client
    @iam_client ||= Aws::IAM::Client.new region: default_region
  end

  def users
    @users ||= begin
      if AwsUtils.cached?('users')
        all_users = AwsUtils.read_cache('users')
      else
        all_users = []
        iam_client.list_users.users.each do |iam_user|
          user = IamUser.new(iam_user, iam_client)
          all_users << user
        end
        AwsUtils.write_cache('users', all_users)
      end
      all_users
    end
  end

  def show_users_by(filter)
    users_filtered = user_filter(filter)
    output_users(filter, users_filtered)
  end

  def show_users_by_key_value(key, value)
    users_filtered = user_key_value_filter(key, value)
    output_users("#{key}: '#{value}'", users_filtered)
  end

  def audit
    subject = 'List of IAM usernames and their active access keys'
    audit_setup('iam_users', subject)
    File.open(@curr_file, 'w') do |f|
      f.puts "### #{subject} #{@fdate} ###\n\n"
      users.each do |user|
        active_keys = user.keys.select { |k| k[:status] == 'Active' }
        f.puts "#{user.name}: <no_active_keys>" if active_keys.empty?
        active_keys.each { |key| f.puts "#{user.name}: #{key[:id]}" }
      end
      f.puts "\n### #{subject} complete ###"
    end
    output_audit_report
  end

  private

  def user_filter(filter)
    case filter
    when 'All'             then users
    when 'Service'         then users.select { |u| u.name.start_with? 'svc_' }
    when 'No_MFA'          then users.select { |u| u.mfa == false }
    when 'Stale_key'
      users.select { |u| u.key_age.to_i > CONFIG['stale_key_days'] || u.key_age == 'no keys!' }
    end
  end

  def user_key_value_filter(key, value)
    case key
    when 'Group' then users.select { |u| u.groups.include? value }
    when 'Name'  then users.select { |u| u.name == value }
    else
      users
    end
  end

  def output_users(filter, users_filtered)
    puts LINE
    unless users_filtered.empty?
      puts USER_LEGEND
      users_filtered.each(&:output_summary)
      puts LINE
      puts USER_LEGEND
      puts DIVIDER
    end
    puts "IAM Users (#{filter}): " + users_filtered.count.to_s.warning
  end
end
