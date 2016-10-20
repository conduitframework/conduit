defmodule Conduit.BrokerTest do
  use ExUnit.Case

  defmodule Broker do
    use Conduit.Broker, otp_app: :my_app

    configure do
      exchange "amq.topic"

      queue "my_app.created.stuff", from: ["#.created.stuff"]
    end

    pipeline :incoming do
      plug Conduit.LoadResource
      plug Conduit.DecodeBody
    end

    pipeline :outgoing do
      plug Conduit.EncodeBody
      plug Conduit.PutCorrelationId
    end

    incoming MyApp.Consumers do
      pipe_through :incoming

      consume "my_app.created.stuff", StuffConsumer
    end

    outgoing do
      pipe_through :outgoing

      publish :more_stuff, exchange: "amq.topic", to: "middle_out.created.more_stuff"
    end
  end

  describe ".exchanges" do
    test "returns a list of all exchanges defined" do
      assert Broker.exchanges == [{"amq.topic", []}]
    end
  end

  describe ".queues" do
    test "returns a list of all queues defined" do
      assert Broker.queues == [{"my_app.created.stuff", [from: ["#.created.stuff"]]}]
    end
  end

  describe ".pipelines" do
    test "returns a list of all the pipelines defined" do
      assert Broker.pipelines == [outgoing: Broker.OutgoingPipeline, incoming: Broker.IncomingPipeline]
    end

    test "returns all pipelines with given names" do
      assert Broker.pipelines(:outgoing) == [outgoing: Broker.OutgoingPipeline]
    end
  end

  describe ".consumers" do
    test "it returns all the consumers defined" do
      assert Broker.consumers == [{
        "my_app.created.stuff",
        [:incoming],
        MyApp.Consumers.StuffConsumer,
        []
      }]
    end
  end

  describe ".publishers" do
    test "it returns all the publishers defined" do
      assert Broker.publishers == [{
        :more_stuff,
        [:outgoing],
        [exchange: "amq.topic", to: "middle_out.created.more_stuff"]
      }]
    end
  end
end
