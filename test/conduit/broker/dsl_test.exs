defmodule Conduit.Broker.DSLTest do
  use ExUnit.Case

  defmodule PassThrough do
    use Conduit.Plug.Builder
  end

  defmodule MyApp.StuffSubscriber do
    use Conduit.Subscriber

    def process(message, _opts), do: message
  end

  defmodule Broker do
    use Conduit.Broker.DSL, otp_app: :my_app

    configure do
      exchange "amq.topic"

      queue "my_app.created.stuff", from: ["#.created.stuff"]
      queue fn config -> config[:node] <> ".dynamic" end, fn config -> [from: ["#.#{config[:node]}.stuff"]] end
    end

    pipeline :incoming do
      plug PassThrough
      plug :put_headers, %{"test" => true}
    end

    pipeline :outgoing do
      plug PassThrough
      plug :put_headers, %{"test" => true}
    end

    incoming Conduit.Broker.DSLTest.MyApp do
      pipe_through :incoming

      subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff"

      subscribe :dynamic, StuffSubscriber,
        from: fn -> Application.get_env(:conduit, :dynamic_from, "my_app.dynamically.created.stuff") end
    end

    outgoing do
      pipe_through :outgoing

      publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"

      publish :dynamic,
        exchange: "amq.topic",
        to: fn -> Application.get_env(:conduit, :dynamic_to, "my_app.created.more_stuff") end
    end
  end

  describe "topology/1" do
    test "returns a list of everything to setup" do
      assert Broker.topology([node: "node1"]) == [
               %Conduit.Topology.Exchange{name: "amq.topic", opts: []},
               %Conduit.Topology.Queue{name: "my_app.created.stuff", opts: [from: ["#.created.stuff"]]},
               %Conduit.Topology.Queue{name: "node1.dynamic", opts: [from: ["#.node1.stuff"]]}
             ]
    end
  end

  describe ".subscribe_routes" do
    test "it returns all the subscribe routes defined" do
      assert [
               %Conduit.SubscribeRoute{
                 name: :stuff,
                 opts: [from: "my_app.created.stuff"],
                 pipelines: [:incoming],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               },
               %Conduit.SubscribeRoute{
                 name: :dynamic,
                 opts: [from: "my_app.dynamically.created.stuff"],
                 pipelines: [:incoming],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               }
             ] == Broker.subscribe_routes()

      Application.put_env(:conduit, :dynamic_from, "my_app.dynamically.created.other_stuff")

      assert [
               %Conduit.SubscribeRoute{
                 name: :stuff,
                 opts: [from: "my_app.created.stuff"],
                 pipelines: [:incoming],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               },
               %Conduit.SubscribeRoute{
                 name: :dynamic,
                 opts: [from: "my_app.dynamically.created.other_stuff"],
                 pipelines: [:incoming],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               }
             ] == Broker.subscribe_routes()

      Application.delete_env(:conduit, :dynamic_from)
    end
  end

  describe "publish_routes" do
    test "it returns all the publish routes defined" do
      assert [
               %Conduit.PublishRoute{
                 name: :more_stuff,
                 opts: [exchange: "amq.topic", to: "my_app.created.more_stuff"],
                 pipelines: [:outgoing]
               },
               %Conduit.PublishRoute{name: :dynamic, opts: [exchange: "amq.topic", to: fun], pipelines: [:outgoing]}
             ] = Broker.publish_routes()

      assert fun.() == "my_app.created.more_stuff"

      Application.put_env(:conduit, :dynamic_to, "my_app.dynamically.created.other_stuff")

      assert [
               %Conduit.PublishRoute{
                 name: :more_stuff,
                 opts: [exchange: "amq.topic", to: "my_app.created.more_stuff"],
                 pipelines: [:outgoing]
               },
               %Conduit.PublishRoute{name: :dynamic, opts: [exchange: "amq.topic", to: fun], pipelines: [:outgoing]}
             ] = Broker.publish_routes()

      assert fun.() == "my_app.dynamically.created.other_stuff"

      Application.delete_env(:conduit, :dynamic_to)
    end
  end

  @error_message "outgoing cannot be nested under anything else"
  test "raises error when outgoing is nested" do
    assert_raise Conduit.BrokerDefinitionError, @error_message, fn ->
      defmodule NestedOutgoingBroker do
        use Conduit.Broker, otp_app: :my_app

        outgoing do
          outgoing do
          end
        end
      end
    end
  end

  @error_message "publish can only be called under an outgoing block"
  test "raises error when publish is called outside outgoing" do
    assert_raise Conduit.BrokerDefinitionError, @error_message, fn ->
      defmodule NestedOutgoingBroker do
        use Conduit.Broker, otp_app: :my_app

        publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
      end
    end
  end

  @error_message "incoming cannot be nested under anything else"
  test "raises error when incoming is nested" do
    assert_raise Conduit.BrokerDefinitionError, @error_message, fn ->
      defmodule NestedOutgoingBroker do
        use Conduit.Broker, otp_app: :my_app

        incoming Conduit.Broker.DSLTest.MyApp do
          incoming Conduit.Broker.DSLTest.MyApp do
          end
        end
      end
    end
  end

  @error_message "subscribe can only be called under an incoming block"
  test "raises error when subscribe is called outside incoming" do
    assert_raise Conduit.BrokerDefinitionError, @error_message, fn ->
      defmodule NestedOutgoingBroker do
        use Conduit.Broker, otp_app: :my_app

        subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff"
      end
    end
  end

  @error_message """
  Duplicate subscribe route named :stuff found in Conduit.Broker.DSLTest.DuplicateSubscribeBroker.

  Subscribe route names must be unique, because they are used to route messages through the correct
  pipelines and to the right subscriber.
  """
  test "raises error when duplicate subscribe routes are defined" do
    assert_raise Conduit.DuplicateRouteError, @error_message, fn ->
      defmodule DuplicateSubscribeBroker do
        use Conduit.Broker, otp_app: :my_app

        incoming Dups do
          subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff"
          subscribe :stuff, StuffSubscriber, from: "my_app.created.stuff"
        end
      end
    end
  end

  @error_message """
  Duplicate publish route named :more_stuff found in Conduit.Broker.DSLTest.DuplicateSubscribeBroker.

  Publish route names must be unique, because they are used to route messages through the correct
  pipelines and send to the right queue.
  """
  test "raises error when duplicate publish routes are defined" do
    assert_raise Conduit.DuplicateRouteError, @error_message, fn ->
      defmodule DuplicateSubscribeBroker do
        use Conduit.Broker, otp_app: :my_app

        outgoing do
          publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
          publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
        end
      end
    end
  end
end
