module NoIpRecordUpdater
  class State
    def initialize
      @running = true
    end

    def running
      @running
    end

    def running=(state)
      @running = state
      if state == false
        Syslog.info("Exiting now")
        exit
      end
    end
  end
end
