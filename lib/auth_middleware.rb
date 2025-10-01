require 'bcrypt'
require 'base64'
require_relative '../db'
require_relative 'app_logger'

class AuthMiddleware
  def self.authenticate_request(request)
    auth_header = request.env['HTTP_AUTHORIZATION']
    return nil unless auth_header&.start_with?('Basic ')
    
    begin
      encoded_credentials = auth_header.split(' ', 2).last
      decoded_credentials = Base64.decode64(encoded_credentials)
      nickname, password = decoded_credentials.split(':', 2)
      
      return nil unless nickname && password
      
      AppLogger.debug("Authentication attempt for user: #{nickname}", "AUTH")
      
      result = DB.exec_params(
        "SELECT id, password_hash FROM credentials WHERE nickname = $1", 
        [nickname]
      )
      
      if result.ntuples == 0
        AppLogger.warn("Authentication failed: user not found: #{nickname}", "AUTH")
        return nil
      end
      
      credential = result[0]
      if BCrypt::Password.new(credential['password_hash']) == password
        AppLogger.info("Authentication successful for user: #{nickname}", "AUTH")
        return {
          credential_id: credential['id'].to_i,
          nickname: nickname
        }
      else
        AppLogger.warn("Authentication failed: invalid password for user: #{nickname}", "AUTH")
        return nil
      end
      
    rescue => e
      AppLogger.error("Authentication error: #{e.message}", "AUTH")
      return nil
    end
  end
  
  def self.set_authenticated_context(db, auth_info)
    db.exec_params("SET app.authenticated_user = $1", [auth_info[:nickname]])
    AppLogger.debug("RLS context set for user: #{auth_info[:nickname]}", "AUTH")
  end
  
  def self.clear_authenticated_context(db)
    db.exec("RESET app.authenticated_user")
    AppLogger.debug("RLS context cleared", "AUTH")
  end
  
  def self.generate_password_hash(password)
    BCrypt::Password.create(password)
  end
end