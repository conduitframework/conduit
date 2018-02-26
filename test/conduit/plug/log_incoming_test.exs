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

      log =
        capture_log(fn ->
          LogIncoming.run(message, log: :info)
        end)

      assert log =~ "Processing message from my.queue"
      assert log =~ ~r/Processed message from my\.queue in \d+(ms|µs)/
    end

    defmodule ErrorPlug do
      use Conduit.Plug.Builder
      plug Conduit.Plug.LogIncoming, log: :info

      def call(_, _, _) do
        raise "error"
      end
    end

    test "it logs error messages from exceptions" do
      message = %Message{source: "my.queue"}

      log =
        capture_log(fn ->
          assert_raise RuntimeError, "error", fn ->
            ErrorPlug.run(message)
          end
        end)

      assert log =~ "Processing message from my.queue"
      assert log =~ "** (RuntimeError) error"
      assert log =~ ~r/Processed message from my\.queue in \d+(ms|µs)/
    end
  end
end
