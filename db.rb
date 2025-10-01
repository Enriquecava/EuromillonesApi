require "pg"
require "dotenv/load"
require_relative "lib/app_logger"

class DatabaseConnection
  def self.connect
    PG.connect(
      host: ENV['PG_HOST'],
      port: ENV['PG_PORT'],
      dbname: ENV['PG_DB'],
      user: ENV['PG_USER'],
      password: ENV['PG_PASSWORD'],
      sslmode: 'require'
    )
  end
  
  def self.set_user_context(connection, user_info)

    nickname = connection.escape_string(user_info[:nickname])
    connection.exec("SET app.authenticated_user = '#{nickname}'")
    AppLogger.debug("RLS context set for user: #{user_info[:nickname]}", "DB")
  end
  
  def self.clear_user_context(connection)
    connection.exec("RESET app.authenticated_user")
    AppLogger.debug("RLS context cleared", "DB")
  end
end

DB = DatabaseConnection.connect
