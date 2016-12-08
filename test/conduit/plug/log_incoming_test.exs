defmodule Conduit.Plug.LogIncomingTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Conduit.Plug.LogIncoming
  alias Conduit.Message

  describe ".init" do
    test "it returns the log level" do
      assert :info = LogIncoming.init([])
      assert :debug = LogIncoming.init(log: :debug)
    end
  end

  describe ".run" do
    test "it logs the message being processed and how long it took" do
      message = %Message{source: "my.queue"}

      log = capture_log(fn ->
        LogIncoming.run(message, log: :info)
      end)

      assert log =~ "Processing message from my.queue"
      assert log =~ ~r/Processed message from my\.queue in \d+(ms|µs)/
    end
  end
end
