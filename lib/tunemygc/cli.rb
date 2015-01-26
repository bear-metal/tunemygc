# encoding: utf-8

require 'net/http'
require 'certified'
require 'timeout'

module TuneMyGc
  class CLI
    TIMEOUT = 10

    attr_reader :email, :uri, :client

    def self.start(args)
      email = args.first
      if email
        new(email).register
      else
        puts "A valid email is required"
      end
    end

    def initialize(email)
      @email = email
      @uri = URI("http://#{TuneMyGc::HOST}/accounts")
      @client = Net::HTTP.new(@uri.host, @uri.port)
      @client.use_ssl = (uri.port == 443)
      @client.read_timeout = TIMEOUT
    end

    def register
      timeout do
        registration = Net::HTTP::Post.new('/accounts')
        registration.set_form_data(:email => @email)
        response = client.request(registration)
        if Net::HTTPUnprocessableEntity === response
          puts "[TuneMyGC] Registration error: #{response.body}"
        else
          puts "[TuneMyGC] Application registered. Use RUBY_GC_TOKEN=#{response.body} in your environment."
        end
      end
    rescue Exception => e
      puts "[TuneMyGC] Registration error: #{e.inspect}"
    end

    private
    def timeout(&block)
      Timeout.timeout(TIMEOUT + 1){ block.call }
    end
  end
end