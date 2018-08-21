defmodule Conduit.Plug.LogOutgoingTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Conduit.Message
  alias Conduit.Plug.LogOutgoing

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
