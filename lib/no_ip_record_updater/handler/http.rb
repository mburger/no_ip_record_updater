require 'net/http'
require 'ipaddr'

module NoIpRecordUpdater
  module Handler
    class HTTP
      def initialize(options, state)
        @options            = options
        @state              = state
        @username           = @options[:username]
        @password           = @options[:password]
        @record             = @options[:record]
        @contact_address    = @options[:contact_address]
        @interval           = @options[:interval]
        @check_ip_uri       = URI(@options[:check_ip_uri])
        @base_update_ip_uri = URI("http://dynupdate.no-ip.com/nic/update")
        @cached_wan_ip      = nil
        @useragent_hash     = { "User-Agent" => "NoIpRecordUpdater/#{NoIpRecordUpdater::VERSION} #{@contact_address}" }

        main_loop
      end

      def main_loop
        Syslog.info("Entering main_loop")
        while @state.running
          (@interval / 2).times do
            sleep 2
          end
          check_ip
        end
      end

      def check_ip
        begin
          res = Net::HTTP.get_response(@check_ip_uri)
          if res.is_a?(Net::HTTPSuccess)
            wan_ip = IPAddr.new res.body.strip
            if wan_ip != @cached_wan_ip
              @cached_wan_ip = wan_ip
              update_record
            end
          end
        rescue Exception => e
          Syslog.err(e.message)
          Syslog.err(e.backtrace.join("\n"))
        end
      end

      def update_record
        begin
          update_uri = @base_update_ip_uri.dup
          query_hash = { :hostname => @record, :myip => @cached_wan_ip }
          update_uri.query = URI.encode_www_form(query_hash)

          req = Net::HTTP::Get.new(update_uri.request_uri, @useragent_hash)
          req.basic_auth @username, @password
          http = Net::HTTP.new(update_uri.hostname, update_uri.port)
          res = http.request(req)

          if res.is_a?(Net::HTTPSuccess)
            case res.body.strip
            when /^good.*$/
              Syslog.info("Successfully updated: #{@record} to #{@cached_wan_ip}")
            when /^nochg.*$/
              Syslog.info("IP address is current, no update performed")
            when /^nohost$/
              Syslog.err("Hostname supplied does not exist under specified account")
              @state.running = false
            when /^badauth$/
              Syslog.err("Invalid username password combination")
              @state.running = false
            when /^badagent$/
              Syslog.err("Client disabled")
              @state.running = false
            when /^!donator$/
              Syslog.err("An update request was sent including a feature that is not available to that particular user such as offline options")
              @state.running = false
            when /^abuse$/
              Syslog.err("Username is blocked due to abuse")
              @state.running = false
            when /^911$/
              Syslog.err("Received Response: #{res.body}, maybe no-ip.org has an outage?")
              Syslog.info("Sleeping for 10 Minutes")
              sleep 600
            else
            end
          end
        rescue Exception => e
          unless e.class == SystemExit
            Syslog.err(e.message)
            Syslog.err(e.backtrace.join("\n"))
          end
        end
      end
    end
  end
end
