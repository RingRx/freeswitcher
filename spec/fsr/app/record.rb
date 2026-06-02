require 'spec/helper'
require "fsr/app"
FSR::App.load_application("record")

describe "Testing FSR::App::Record" do
  it "Records a file with path only (FreeSWITCH-side defaults for the rest)" do
    record = FSR::App::Record.new("/tmp/voicemail/abc123.wav")
    record.sendmsg.should == "call-command: execute\nexecute-app-name: record\nexecute-app-arg: /tmp/voicemail/abc123.wav\nevent-lock:true\n\n"
  end

  it "Records a file with a time limit" do
    record = FSR::App::Record.new("/tmp/voicemail/abc123.wav", 180)
    record.sendmsg.should == "call-command: execute\nexecute-app-name: record\nexecute-app-arg: /tmp/voicemail/abc123.wav 180\nevent-lock:true\n\n"
  end

  it "Records a file with time limit, silence threshold, and silence seconds" do
    record = FSR::App::Record.new("/tmp/voicemail/abc123.wav", 180, 200, 7)
    record.sendmsg.should == "call-command: execute\nexecute-app-name: record\nexecute-app-arg: /tmp/voicemail/abc123.wav 180 200 7\nevent-lock:true\n\n"
  end

  it "Omits trailing nil arguments rather than emitting empty fields" do
    # silence_threshold present but silence_secs absent -> three args, no
    # trailing space or empty token.
    record = FSR::App::Record.new("/tmp/voicemail/abc123.wav", 180, 200)
    record.arguments.should == ["/tmp/voicemail/abc123.wav", 180, 200]
  end

  it "Exposes the path it was constructed with" do
    record = FSR::App::Record.new("/tmp/voicemail/abc123.wav", 180)
    record.path.should == "/tmp/voicemail/abc123.wav"
  end
end
