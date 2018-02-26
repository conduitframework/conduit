defmodule Conduit.Plug.LogOutgoingTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Conduit.Plug.LogOutgoing
  alias Conduit.Message

  describe ".init" do
    test "it returns the log level" do
      assert :info = LogOutgoing.init([])
      assert :debug = LogOutgoing.init(log: :debug)
    end
  end

  describe ".run" do
    test "it logs the message being processed and how long it took" do
      message = %Message{destination: "my.queue"}

      log =
        capture_log(fn ->
          LogOutgoing.run(message, log: :info)
        end)

      assert log =~ "Sending message to my.queue"
      assert log =~ ~r/Sent message to my\.queue in \d+(ms|µs)/
    end

    defmodule ErrorPlug do
      use Conduit.Plug.Builder
      plug Conduit.Plug.LogOutgoing, log: :info

      def call(_, _, _) do
        raise "error"
      end
    end

    test "it logs error messages from exceptions" do
      message = %Message{destination: "my.queue"}

      log =
        capture_log(fn ->
          assert_raise RuntimeError, "error", fn ->
            ErrorPlug.run(message)
          end
        end)

      assert log =~ "Sending message to my.queue"
      assert log =~ "** (RuntimeError) error"
      assert log =~ ~r/Sent message to my\.queue in \d+(ms|µs)/
    end
  end
end
