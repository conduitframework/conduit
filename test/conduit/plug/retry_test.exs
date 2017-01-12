defmodule Conduit.Plug.RetryTest do
  use ExUnit.Case
  import Conduit.Message

  describe ".init" do
    test "it merges passed opts and returns a map" do
      assert Conduit.Plug.Retry.init([]) == %{
        attempts: 3,
        backoff_factor: 2,
        jitter: 0,
        delay: 1000
      }

      assert Conduit.Plug.Retry.init([attempts: 2, jitter: 3]) == %{
        attempts: 2,
        backoff_factor: 2,
        jitter: 3,
        delay: 1000
      }
    end
  end

  describe "when there is an error" do
    defmodule ErroredRetry do
      use Conduit.Subscriber
      plug Conduit.Plug.Retry, attempts: 2, delay: 2

      def process(message, _opts) do
        send(self(), {:process, message})
        raise "failure"
      end
    end

    test "it retries and after failing reraises the error" do
      assert_raise(RuntimeError, "failure", fn ->
        ErroredRetry.run(%Conduit.Message{})
      end)

      assert_received({:process, first_message})
      assert_received({:process, second_message})

      assert get_header(first_message, "retries") == nil
      assert get_header(second_message, "retries") == 1

      assert first_message.status == :ack
      assert second_message.status == :ack
    end
  end

  describe "when first message failes, but second succeeds" do
    defmodule PartiallyErroredRetry do
      use Conduit.Subscriber
      plug Conduit.Plug.Retry, attempts: 2, delay: 2

      def process(message, _opts) do
        if get_header(message, "retries") do
          send(self(), {:process, :success, message})
          message
        else
          send(self(), {:process, :failure, message})
          raise "failure"
        end
      end
    end

    test "it retries and succeeds" do
      assert %Conduit.Message{status: :ack} = PartiallyErroredRetry.run(%Conduit.Message{})

      assert_received({:process, :failure, first_message})
      assert_received({:process, :success, second_message})

      assert get_header(first_message, "retries") == nil
      assert get_header(second_message, "retries") == 1

      assert first_message.status == :ack
      assert second_message.status == :ack
    end
  end

  describe "when the message is nacked" do
    defmodule NackedRetry do
      use Conduit.Subscriber
      plug Conduit.Plug.Retry, attempts: 2, delay: 2

      def process(message, _opts) do
        send(self(), {:process, message})
        nack(message)
      end
    end

    test "it retries and eventually returns the nacked message" do
      assert %Conduit.Message{status: :nack} = NackedRetry.run(%Conduit.Message{})

      assert_received({:process, first_message})
      assert_received({:process, second_message})

      assert get_header(first_message, "retries") == nil
      assert get_header(second_message, "retries") == 1

      assert first_message.status == :ack
      assert second_message.status == :ack
    end
  end

  describe "when the message is successful" do
    defmodule NoRetry do
      use Conduit.Subscriber
      plug Conduit.Plug.Retry, attempts: 2, delay: 2

      def process(message, _opts) do
        send(self(), {:process, message})
        message
      end
    end

    test "it does not retry" do
      assert %Conduit.Message{status: :ack} = NoRetry.run(%Conduit.Message{})

      assert_received({:process, first_message})
      refute_received({:process, %Conduit.Message{}})

      assert get_header(first_message, "retries") == nil

      assert first_message.status == :ack
    end
  end
end
