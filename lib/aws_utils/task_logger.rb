# frozen_string_literal: true

require 'logger'

# Write to log file and colorized to stdout
class TaskLogger
  attr_reader :logger

  def initialize(logfile)
    @logger = begin
      FileUtils.mkdir_p File.dirname(logfile)
      logger = Logger.new logfile
      logger.progname = 'AWSUtils'
      logger.formatter = proc { |severity, datetime, _progname, msg|
        case severity
        when 'INFO' then puts " #{severity}: #{msg}".light_green
        when 'DEBUG' then puts "#{severity}: #{msg}".light_cyan
        when 'WARN' then puts " #{severity}: #{msg}".light_yellow
        when 'ERROR' then puts "#{severity}: #{msg}".light_red
        when 'FATAL' then puts "#{severity}: #{msg}".red
        else
          puts msg
        end
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        format_space = severity.length == 4 ? ' ' : '' # for even columnar log reading
        "[#{date_format}] #{severity}#{format_space}: #{msg}\n"
      }
      logger
    end
  end
end
