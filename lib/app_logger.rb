require 'logger'
require 'dotenv/load'

class AppLogger
  def self.instance
    @logger ||= create_logger
  end

  def self.create_logger
    # Determine log level based on environment variable
    log_level = case ENV['LOG_LEVEL']&.downcase
                when 'debug' then Logger::DEBUG
                when 'info' then Logger::INFO
                when 'warn' then Logger::WARN
                when 'error' then Logger::ERROR
                when 'fatal' then Logger::FATAL
                else Logger::INFO
                end

    # Determine log destination based on environment
    log_destination = if ENV['APP_ENV'] == 'production'
                        'log/app.log'
                      elsif ENV['APP_ENV'] == 'test'
                        'log/test.log'
                      else
                        STDOUT
                      end

    logger = Logger.new(log_destination, 'daily')
    logger.level = log_level
    
    # Custom format for logs
    logger.formatter = proc do |severity, datetime, progname, msg|
      timestamp = datetime.strftime('%Y-%m-%d %H:%M:%S')
      "[#{timestamp}] #{severity.ljust(5)} #{progname}: #{msg}\n"
    end

    logger
  end

  # Convenience methods for logging
  def self.debug(message, progname = 'APP')
    instance.debug(progname) { message }
  end

  def self.info(message, progname = 'APP')
    instance.info(progname) { message }
  end

  def self.warn(message, progname = 'APP')
    instance.warn(progname) { message }
  end

  def self.error(message, progname = 'APP')
    instance.error(progname) { message }
  end

  def self.fatal(message, progname = 'APP')
    instance.fatal(progname) { message }
  end

  # Method for logging HTTP requests
  def self.log_request(method, path, status, duration = nil, user_email = nil)
    user_info = user_email ? " [User: #{user_email}]" : ""
    duration_info = duration ? " (#{duration.round(3)}s)" : ""
    info("#{method.upcase} #{path} -> #{status}#{duration_info}#{user_info}", 'HTTP')
  end

  # Method for logging database errors
  def self.log_db_error(operation, error, context = {})
    context_str = context.empty? ? "" : " Context: #{context.inspect}"
    error("DB #{operation} failed: #{error.message}#{context_str}", 'DATABASE')
  end

  # Method for logging validation errors
  def self.log_validation_error(field, value, error_message)
    warn("Validation failed for #{field} (#{value}): #{error_message}", 'VALIDATION')
  end
end