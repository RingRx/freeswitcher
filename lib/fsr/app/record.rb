require "fsr/app"
require 'fsr/file_methods'

module FSR
  # http://wiki.freeswitch.org/wiki/Misc._Dialplan_Tools_record
  #
  # The `record` dialplan application records a SINGLE file from the
  # channel's audio. This is distinct from `record_session`, which records
  # an entire (typically bridged) session to disk via media bugs. For the
  # voicemail deposit flow we want `record`: one caller, one file, with a
  # hard time limit and trailing-silence auto-stop.
  #
  # FreeSWITCH application syntax:
  #
  #   record <path> [<time_limit_seconds>] [<silence_threshold>] [<silence_seconds>]
  #
  #   path             absolute filesystem path FreeSWITCH writes the file to.
  #                    The extension selects the encoder (.wav => L16/PCM).
  #   time_limit_secs  hard cap on recording length; FS stops at this point.
  #   silence_thresh   energy level below which audio counts as silence
  #                    (FreeSWITCH default ~200; higher = less sensitive).
  #   silence_secs     seconds of trailing silence that auto-stops recording.
  #
  # Termination DTMF is controlled by the `playback_terminators` channel
  # variable (set separately via the `set` app or on the originating
  # dialplan), not by a record-app argument. On completion FreeSWITCH sets
  # the channel variables `record_ms`, `record_seconds`, and (if a DTMF
  # ended the recording) `playback_terminator_used` — the IVR layer reads
  # these back to populate its RecordResult.
  #
  # Because `record` carries no custom SENDMSG_METHOD, FSR::Listener::Outbound
  # wraps it with the generic definition (sendmsg + a single queued block).
  # With event-lock:true the command reply — and therefore the queued
  # block — fires only after the recording finishes (time limit, trailing
  # silence, terminator DTMF, or hangup), which is exactly the completion
  # signal the synchronous IVR bridge blocks on.
  module App
    class Record < Application

      include ::FSR::App::FileMethods

      attr_reader :path, :time_limit, :silence_threshold, :silence_secs

      # path is required; the three tuning args are optional and only
      # appended to the application argument string when present, so the
      # FreeSWITCH-side defaults apply when they're omitted.
      def initialize(path, time_limit = nil, silence_threshold = nil, silence_secs = nil)
        @path              = path
        @time_limit        = time_limit
        @silence_threshold = silence_threshold
        @silence_secs      = silence_secs
      end

      def arguments
        [@path, @time_limit, @silence_threshold, @silence_secs].compact
      end

      def sendmsg
        "call-command: execute\nexecute-app-name: %s\nexecute-app-arg: %s\nevent-lock:true\n\n" % [app_name, arguments.join(" ")]
      end
    end

    register(:record, Record)
  end
end
