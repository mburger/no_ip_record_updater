require 'no_ip_record_updater/state'
require 'no_ip_record_updater/handler/http'

module NoIpRecordUpdater
  module CLI
    class Run
      def initialize(options)
        @options  = options
        @state    = NoIpRecordUpdater::State.new

        dispatch
      end

      def dispatch
        setup_logging
        if @options[:daemonize]
          run_daemonize
        else
          run_in_front
        end
      end

      def run_daemonize
        pid = fork do
          begin
            ["TERM", "INT"].each do |signal|
              Signal.trap(signal) do
                @state.running = false
              end
            end
            start_handler
          rescue Exception => e
            unless e.class == SystemExit
              Syslog.err(e.class)
              Syslog.err(e.message)
              Syslog.err(e.backtrace.join("\n"))
            end
          end
        end
        Syslog.info("Detaching forked Process")
        Process.detach pid
        exit
      end

      def run_in_front
        start_handler
      end

      def start_handler
        NoIpRecordUpdater::Handler::HTTP.new(@options, @state)
      end

      def setup_logging
        require 'syslog'
        Syslog.open("NoIpRecordUpdater", Syslog::LOG_PID)
      end
    end
  end
end
