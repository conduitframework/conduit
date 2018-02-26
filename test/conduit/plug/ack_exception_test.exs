defmodule Conduit.Plug.AckExceptionTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  defmodule ExceptionRaiser do
    use Conduit.Subscriber
    plug Conduit.Plug.AckException

    def process(_message, _) do
      raise "failure"
    end
  end

  test "it acks the message if an exception is raised" do
    capture_log(fn ->
      message =
        %Conduit.Message{}
        |> Conduit.Message.nack()
        |> ExceptionRaiser.run()

      assert message.status == :ack
    end)
  end
end
