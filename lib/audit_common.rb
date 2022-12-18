# frozen_string_literal: true

# shared methods for running the audit tasks
module AuditCommon
  def audit_setup(service, subject)
    puts "- Creating audit: #{subject}".running
    @fdate = Time.now.strftime('%Y-%m-%d')
    @audit_dir = "#{AUDIT_PATH}/#{service}"
    FileUtils.mkdir_p @audit_dir
    @prev_file = Dir.glob("#{@audit_dir}/**/*.yaml").max_by { |f| File.mtime(f) }
    @curr_file = "#{@audit_dir}/#{service}_#{@fdate}.yaml"
    @diff_file = "#{@audit_dir}/#{service}_#{@fdate}.diff"
  end

  def output_audit_report
    return unless !@prev_file.nil? && File.exist?(@prev_file)

    File.open(@diff_file, 'a') { |f| f.puts Diffy::Diff.new(@prev_file, @curr_file, source: 'files') }
    puts "- See audit diff at #{@diff_file}".direct
  end
end
