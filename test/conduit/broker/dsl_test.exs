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
      subscribe :dynamic, StuffSubscriber, from: fn -> "my_app.dynamically.created.stuff" end
    end

    outgoing do
      pipe_through :outgoing

      publish :more_stuff, exchange: "amq.topic", to: "my_app.created.more_stuff"
    end
  end

  describe ".topology" do
    test "returns a list of everything to setup" do
      assert Broker.topology() == [
               %Conduit.Broker.Topology.Exchange{name: "amq.topic", opts: []},
               %Conduit.Broker.Topology.Queue{name: "my_app.created.stuff", opts: [from: ["#.created.stuff"]]}
             ]
    end
  end

  describe ".subscribe_routes" do
    test "it returns all the subscribe routes defined" do
      assert Broker.subscribe_routes() == [
               %Conduit.Broker.SubscribeRoute{
                 name: :stuff,
                 opts: [from: "my_app.created.stuff"],
                 pipelines: [
                   %Conduit.Broker.Pipeline{
                     name: :incoming,
                     plugs: [
                       {:put_headers, %{"test" => true}},
                       {Conduit.Broker.DSLTest.PassThrough, []}
                     ]
                   }
                 ],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               },
               %Conduit.Broker.SubscribeRoute{
                 name: :dynamic,
                 opts: [from: "my_app.dynamically.created.stuff"],
                 pipelines: [
                   %Conduit.Broker.Pipeline{
                     name: :incoming,
                     plugs: [{:put_headers, %{"test" => true}}, {Conduit.Broker.DSLTest.PassThrough, []}]
                   }
                 ],
                 subscriber: Conduit.Broker.DSLTest.MyApp.StuffSubscriber
               }
             ]
    end
  end

  describe "publish_routes" do
    test "it returns all the publish routes defined" do
      assert Broker.publish_routes() == [
               %Conduit.Broker.PublishRoute{
                 name: :more_stuff,
                 opts: [exchange: "amq.topic", to: "my_app.created.more_stuff"],
                 pipelines: [
                   %Conduit.Broker.Pipeline{
                     name: :outgoing,
                     plugs: [
                       {:put_headers, %{"test" => true}},
                       {Conduit.Broker.DSLTest.PassThrough, []}
                     ]
                   }
                 ]
               }
             ]
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
end
