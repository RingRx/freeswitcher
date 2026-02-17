require "fsr/app"
module FSR
  module Cmd
    class Calls < Command

      include Enumerable
      TYPES = [:detailed, :bridged, :detailed_bridged]
      def each(&block)
        @calls ||= run
        if @calls
          @calls.each { |call| yield call }
        end
      end

      def initialize(fs_socket = nil, type = nil, filter = nil)
        @type = type
        @filter = filter
        unless @type.nil?
          raise ArgumentError, "Only #{TYPES} are allowed as arguments" unless TYPES.include?(@type)
        end
        @fs_socket = fs_socket # FSR::CommandSocket obj
      end

      # Send the command to the event socket, using bgapi by default.
      def run(api_method = :api)
        orig_command = "%s %s" % [api_method, raw]
        Log.debug "saying #{orig_command}"
        resp = @fs_socket.say(orig_command)
        body = resp["body"].to_s.strip
        return [] if body.empty? || body == "0 total." || body.start_with?("-ERR")

        require "fsr/model/call"
        require "json"

        # Use JSON output from FreeSWITCH - avoids CSV parsing issues with fields containing commas
        begin
          data = JSON.parse(body)
          rows = data["rows"] || []
          @calls = rows.map { |row| FSR::Model::Call.new(row.keys, *row.values) }
          return @calls
        rescue JSON::ParserError => e
          Log.error "Failed to parse calls JSON: #{e.message}"
          return []
        end
      end

      # This method builds the API command to send to the freeswitch event socket
      def raw
        base = if @type.nil?
          "show calls as json"
        else
          "show %s_calls as json" % @type
        end
        if @filter
          "%s like '%s'" % [base.sub(' as json', ''), @filter] + " as json"
        else
          base
        end
      end
    end

    register(:calls, Calls)
  end
end
