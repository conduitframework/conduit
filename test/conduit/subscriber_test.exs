defmodule Conduit.SubscriberTest do
  use ExUnit.Case, async: true
  alias Conduit.Message

  describe "run/2" do
    defmodule JustSub do
      @moduledoc false
      use Conduit.Subscriber

      def process(message, opts) do
        send(self(), {:process, message, opts})

        message
      end
    end

    test "calls perform/2 with the message and opts passed through when just subscriber" do
      JustSub.run(%Message{}, foo: :bar)

      assert_received {:process, %Message{}, foo: :bar}
    end

    defmodule SubWithPlug do
      @moduledoc false
      use Conduit.Subscriber
      plug :put_correlation_id, "1"

      def process(message, opts) do
        send(self(), {:process, message, opts})

        message
      end
    end

    test "calls perform/2 with the message and opts passed through when subscriber with plug" do
      SubWithPlug.run(%Message{}, foo: :bar)

      assert_received {:process, %Message{correlation_id: "1"}, foo: :bar}
    end
  end
end
