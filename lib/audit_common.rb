module AuditCommon
  AUDIT_PATH = File.join(File.dirname(__FILE__), '../audit_reports')

  def setup(service)
    @fdate = Time.now.strftime('%Y-%m-%d')
    @audit_dir = "#{AUDIT_PATH}/#{service}"
    FileUtils.mkdir_p @audit_dir
    @prev_file = Dir.glob("#{@audit_dir}/**/*.yaml").max_by {|f| File.mtime(f)}
    @curr_file = "#{@audit_dir}/#{service}_#{@fdate}.yaml"
    @diff_file = "#{@audit_dir}/#{service}_#{@fdate}.diff"
  end

  def output_msg
    puts 'complete.'.green
    if !@prev_file.nil? && File.exist?(@prev_file)
      open(@diff_file, 'a') { |f| f.puts Diffy::Diff.new(@prev_file, @curr_file, source: 'files') }
      puts "diff file created at #{@diff_file}".yellow
    end
  end
end