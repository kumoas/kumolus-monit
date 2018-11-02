require "active_support/json"
require "active_support/xml_mini"
require "active_support/core_ext/hash/conversions"
require "net/http"
require "net/https"
require "uri"

module Kumolus
  module Monit

    class Status
      ::ActiveSupport::XmlMini.backend = "Nokogiri"

      attr_reader :url, :hash, :xml, :server, :platform, :services
      attr_accessor :username, :auth, :host, :port, :ssl, :auth, :username
      attr_writer :password

      def initialize(options = {})
        @host     = options[:host]    || "localhost"
        @port     = (options[:port]   || 2812).to_i
        @ssl      = options[:ssl]     || false
        @auth     = options[:auth]    || false
        @path 	  = options[:path]
        @username = options[:username]
        @password = options[:password]
        @services = []
      end

      def url
        url_params = { :host => @host, :port => @port, :path => "#{@path}/_status", :query => "format=xml" }
        @ssl ? URI::HTTPS.build(url_params) : URI::HTTP.build(url_params)
      end

      def get
        uri = self.url
        http = Net::HTTP.new(uri.host, uri.port)

        if @ssl
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        request = Net::HTTP::Get.new(uri.request_uri)

        if @auth
          request.basic_auth(@username, @password)
        end

        request["User-Agent"] = "Monit Ruby client #{Monit::VERSION}"

        begin
          response = http.request(request)
        rescue Errno::ECONNREFUSED
          return false
        end

        if (response.code =~ /\A2\d\d\z/)
          @xml = response.body
          return self.parse(@xml)
        else
          return false
        end
      end

      def parse(xml)
        @hash     = Hash.from_xml(xml)
        @server   = Kumolus::Monit::Server.new(@hash["monit"]["server"])
        @platform = Kumolus::Monit::Platform.new(@hash["monit"]["platform"])

        options = {
          :host     => @host,
          :port     => @port,
          :ssl      => @ssl,
          :auth     => @auth,
          :username => @username,
          :password => @password
        }

        if @hash["monit"]["service"].is_a? Array
          @services = @hash["monit"]["service"].map do |service|
            Kumolus::Monit::Service.new(service, options)
          end
        else
          @services = [Kumolus::Monit::Service.new(@hash["monit"]["service"], options)]
        end
        true
      rescue
        false
      end
    end
  end
end
