require "fsr/app"
module FSR
  module Cmd
    class Channels < Command

      include Enumerable
      def each(&block)
        @channels ||= run
        if @channels
          @channels.each { |call| yield call }
        end
      end

      def initialize(fs_socket = nil, filter = nil)
        @filter = filter
        @filter = nil if @filter === false
        @fs_socket = fs_socket # FSR::CommandSocket obj
      end

      # Send the command to the event socket, using bgapi by default.
      def run(api_method = :api)
        orig_command = "%s %s" % [api_method, raw]
        Log.debug "saying #{orig_command}"
        resp = @fs_socket.say(orig_command)
        if resp["body"] =~ /USAGE/
          Log.warn "This server does not support #{raw}, trying Calls"
          return Calls.new(@fs_socket, :detailed).run
        else
          body = resp["body"].to_s.strip
          return [] if body.empty? || body == "0 total." || body.start_with?("-ERR")

          require "fsr/model/channel"
          require "json"

          # Use JSON output from FreeSWITCH - avoids CSV parsing issues with fields containing commas
          begin
            data = JSON.parse(body)
            rows = data["rows"] || []
            @channels = rows.map { |row| FSR::Model::Channel.new(row.keys, *row.values) }
            return @channels
          rescue JSON::ParserError => e
            Log.error "Failed to parse channels JSON: #{e.message}"
            return []
          end
        end
      end

      # This method builds the API command to send to the freeswitch event socket
      def raw
        if @filter === true
          'show distinct_channels as json'
        elsif @filter.nil?
          'show channels as json'
        elsif @filter.is_a?(Fixnum)
          'show channels %d as json' % @filter
        elsif @filter.is_a?(String)
          "show channels like '%s' as json" % @filter
        else
          'show channels as json'
        end
      end
    end

    register(:channels, Channels)
  end
end
