# encoding: utf-8

require 'net/http'
require 'certified'
require 'timeout'
require 'optparse'

module TuneMyGc
  class CLI
    TIMEOUT = 10

    attr_reader :uri, :client, :options

    def self.start(args)
      args = ["-h"] if args.empty?
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: tunemygc [options]"

        opts.on("-r ", "--register EMAIL", "Register this Rails app with the https://tunemygc.com service") do |email|
          options[:email] = email
        end
        opts.on("-c ", "--config TOKEN", "Fetch the last known config for a given Rails app") do |token|
          options[:config] = token
        end
        opts.on_tail("-h", "--help", "How to use the TuneMyGC agent CLI") do
          puts opts
          exit
        end
      end.parse!(args)
      new(options)
    end

    def initialize(options)
      @options = options
      @uri = URI("http://#{TuneMyGc::HOST}")
      @client = Net::HTTP.new(@uri.host, @uri.port)
      @client.use_ssl = (uri.port == 443)
      @client.read_timeout = TIMEOUT
      register if options[:email]
      fetch_config if options[:config]
    end

    def register
      timeout do
        registration = Net::HTTP::Post.new('/accounts')
        registration.set_form_data(:email => options[:email])
        response = client.request(registration)
        if Net::HTTPUnprocessableEntity === response
          puts "Registration error: #{response.body}"
        elsif Net::HTTPSuccess === response
          puts "Application registered. Use RUBY_GC_TOKEN=#{response.body} in your environment."
        else
          puts "Registration error: #{response.body}"
        end
      end
    rescue Exception => e
      puts "Registration error: #{e.inspect}"
    end

    def fetch_config
      timeout do
        config = Net::HTTP::Get.new("/apps/#{options[:config]}")
        response = client.request(config)
        if Net::HTTPNoContent === response
          puts "There is no configuration for Rails app with token #{options[:config]} yet"
        elsif Net::HTTPNotFound === response
          puts "Rails app with token #{options[:config]} doesn't exist"
        elsif Net::HTTPSuccess === response
          puts "=== Suggested GC configuration:"
          puts
          puts response.body
        else
          puts "Config retrieval error: #{response.body}"
        end
      end
    rescue Exception => e
      puts "Config retrieval error: #{e.inspect}"
    end

    private
    def timeout(&block)
      Timeout.timeout(TIMEOUT + 1){ block.call }
    end
  end
end