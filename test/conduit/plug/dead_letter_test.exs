defmodule Conduit.Plug.DeadLetterTest do
  use ExUnit.Case

  defmodule Broker do
    def publish(name, message, opts) do
      send(self, {:publish, name, message, opts})
    end
  end

  describe "when the message is nacked" do
    defmodule NackedDeadLetter do
      use Conduit.Subscriber
      plug Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error

      def process(message, _) do
        nack(message)
      end
    end

    test "it publishes the message to the dead letter destination and acks the message" do
      assert %Conduit.Message{status: :ack} = NackedDeadLetter.run(%Conduit.Message{})

      assert_received {:publish, :error, %Conduit.Message{}, broker: Broker, publish_to: :error}
    end
  end

  describe "when the message has errored" do
    defmodule ErroredDeadLetter do
      use Conduit.Subscriber
      plug Conduit.Plug.DeadLetter, broker: Broker, publish_to: :error

      def process(_message, _opts), do: raise "failure"
    end

    test "it publishes the message to the dead letter destination and reraises the error" do
      assert_raise(RuntimeError, "failure", fn ->
        ErroredDeadLetter.run(%Conduit.Message{})
      end)
      assert_received {:publish, :error, %Conduit.Message{}, broker: Broker, publish_to: :error}
    end
  end
end
