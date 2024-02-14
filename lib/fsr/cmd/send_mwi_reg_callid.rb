# Adding the send_mwi method

require "fsr/app"
module FSR
  module Cmd
    class SendMwiRegCallId < Command
      def initialize(fs_socket = nil, args = {})
        @fs_socket = fs_socket # FSR::CommandSocket obj
        @reg_callid, @aor, new, read = args.values_at(:reg_callid, :aor, :new, :read)
        @read = read.to_i || 0
        @new = new.to_i || 0
        raise(ArgumentError, "No reg_callid given") unless @reg_callid
        raise(ArgumentError, "No aor given") unless @aor
        if @new.zero?
          @options = "\r\nMWI-Messages-Waiting: no\r\nCall-Id:#{@reg_callid}\r\nMWI-Message-Account: sip:#{@aor}"
        else
          @options = "\r\nMWI-Messages-Waiting: yes\r\nCall-Id:#{@reg_callid}\r\nMWI-Message-Account: sip:#{@aor}\r\nMWI-Voice-Message: #{@new}/#{@read} (0/0)"
        end
      end

      # Send the command to the event socket, using api by default.
      def run
        orig_command = raw
        Log.debug "saying 2 #{orig_command}"
        puts "saying #{orig_command}"
        @fs_socket.say(orig_command)
      end
    
      # This method builds the API command to send to the freeswitch event socket
      def raw
        orig_command = "sendevent  message_waiting#{@options}"
      end
    end

    register(:send_mwi_reg_callid, SendMwiRegCallId)
  end
end
