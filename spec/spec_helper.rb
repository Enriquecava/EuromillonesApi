require 'rspec'
require 'rack/test'
require 'json'
require 'date'

ENV['RACK_ENV'] = 'test'

require_relative '../routes/result'

RSpec.configure do |config|

  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  config.before(:each) do

    stub_const('DB', double('DB'))
    allow(DB).to receive(:exec_params).and_return([]) 


    stub_const('AppLogger', double('AppLogger').as_null_object)


    stub_const('Validators', Module.new)
    allow(Validators).to receive(:valid_date_format?).and_return(true)
    allow(Validators).to receive(:contains_suspicious_patterns?).and_return(false)
    allow(Validators).to receive(:valid_euromillones_draw_day?).and_return(false)
    allow(Validators).to receive(:validation_error).and_return({ error: 'validation failed' })

    stub_const('ValidationMiddleware', Module.new)
    allow(ValidationMiddleware).to receive(:validate_request).and_return(true)
    allow(ValidationMiddleware).to receive(:sanitize_url_params) { |params| params }
    
    allow(Validators).to receive(:validation_error) do |message, field|
      { error: message, field: field }
    end
  end

  config.after(:each) do

  end

  config.order = :defined
  config.formatter = :documentation
end
