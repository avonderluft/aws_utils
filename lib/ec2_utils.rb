# frozen_string_literal: true

require_relative 'aws_utils'
require_relative 'ec2/ec2_instances'

# to query AWS EC2 instances
class Ec2Utils < AwsUtils
  include Ec2Instances
  include Ec2Regions

  def show_by_id_or_name(id_or_name)
    puts LINE
    found_instances = ec2s.select { |i| i.name == id_or_name }
    found_instances = ec2s.select { |i| i.id.include? id_or_name } if found_instances.empty?
    found_instances.each { |ec2| output_object(ec2, ec2.state_color) }
    puts LINE
  end

  def show_tags
    puts LINE
    ec2s.each do |ec2|
      puts DIVIDER if ec2s.count > 1 && ec2 != ec2s.first
      puts "Tags for #{ec2.id.identify}"
      ap ec2.tags, indent: -2, multiline: true, color: { string: ec2.state_color }
    end
    puts LINE
  end

  def show_by_tag(tag)
    if all_tag_keys.include? tag
      tag_ec2s = ec2s.select { |i| i.tags[tag] }
      puts LINE
      puts "Tag: #{tag.filter}  Count: #{tag_ec2s.count.to_s.yellow}#{EC2_LEGEND}"
      output_by_region(ec2s, "tag '#{tag}'", tag_ec2s, EC2_LEGEND)
      puts ec2_detail_instructions
    else
      puts "No EC2 instances have the tag '#{tag}'".error
    end
  end

  def show_by_type(type_arg)
    if instance_types.include? type_arg
      type_ec2s = type_arg == 'all' ? ec2s : ec2s.select { |i| i.instance_type == type_arg }
      output_by_region(ec2s, type_arg, type_ec2s, EC2_LEGEND)
      puts ec2_detail_instructions
    else
      puts LINE
      puts "'#{type_arg}' is not a valid instance type.".error
      puts "run 'rake ec2s:types[<optional_filter>]' to see available types".direct
      puts DIVIDER
    end
  end

  def show_by_regions(filter)
    output_by_region(ec2s, filter, ec2s_filter(filter), EC2_LEGEND)
    puts ec2_detail_instructions
  end

  def ec2_detail_instructions
    @ec2_detail_instructions ||=
      "For detail on an instance: specify ec2 id or name e.g. 'rake ec2[#{ec2s.last.id}]'\n".direct +
      "For detail on a block device: specify volume_id e.g. 'rake vol[volume_id]'\n".direct         +
      DIVIDER
  end

  def show_instance_types(filter = 'all')
    types = instance_types
    types.select! { |t| t.include? filter } if filter
    puts types.to_s.info
    puts DIVIDER
    puts "To filter types shown, add argument, e.g 'rake ec2s:types[t3a]".direct
    puts DIVIDER
  end

  def audit
    subject = 'List of EC2 instances and their SSH keys'
    audit_setup('ec2_keys', subject)
    File.open(@curr_file, 'w') do |f|
      f.puts "### #{subject} #{@fdate} ###\n"
      yaml_output = {}
      ec2_used_regions.each do |region|
        ec2s_hash = {}
        ec2s_by_region(region).each do |ec2|
          ec2s_hash[ec2.id] = { 'name' => ec2.name, 'key' => ec2.key_name }
        end
        yaml_output[region] = ec2s_hash
      end
      f.puts yaml_output.to_yaml
      f.puts "\n### #{subject} complete ###"
    end
    output_audit_report
  end

  private

  def all_tag_keys
    @all_tag_keys ||= ec2s.map(&:tags).reduce({}, :merge).keys
  end

  def ec2s_filter(filter)
    case filter
    when 'large'      then ec2s_filter('running').select { |i| i.instance_type.include? 'large' }
    when 'new'        then ec2s_filter('running').reject { |i| i.uptime =~ /(days|years)/ }
    when 'running'    then ec2s.select { |i| i.state == 'running' }
    when 'stopped'    then ec2s.select { |i| %w[stopped shutting-down].include? i.state }
    when 'terminated' then ec2s.select { |i| i.state == 'terminated' }
    else
      ec2s
    end
  end

  def instance_types
    @instance_types ||=
      resp = ec2_client.describe_instance_type_offerings
    resp.instance_type_offerings.map(&:instance_type)
  end
end
