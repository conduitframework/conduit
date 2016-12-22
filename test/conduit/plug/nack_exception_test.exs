defmodule Conduit.Plug.NackExceptionTest do
  use ExUnit.Case

  defmodule ExceptionRaiser do
    use Conduit.Subscriber
    plug Conduit.Plug.NackException

    def process(_message, _) do
      raise "failure"
    end
  end

  test "it nacks the message if an exception is raised" do
    message = ExceptionRaiser.run(%Conduit.Message{})

    assert message.status == :nack
  end
end
