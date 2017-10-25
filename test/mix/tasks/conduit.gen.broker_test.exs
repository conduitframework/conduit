defmodule Mix.Tasks.Conduit.Gen.BrokerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Mix.Tasks.Conduit.Gen.Broker, as: GenBroker

  setup do
    File.rm_rf("tmp")
    on_exit(fn ->
      File.rm_rf("tmp")
    end)

    :ok
  end

  describe "run/1" do
    test "raises exception when invalid switch is passed" do
      assert_raise OptionParser.ParseError, fn ->
        GenBroker.run(["foo", "--something-broken"])
      end
    end

    test "creates broker in specified directory" do
      assert capture_io(fn ->
        GenBroker.run(["tmp/my_app1"])
      end) == """
      \e[32m* creating \e[0mtmp/my_app1\e[0m
      \e[32m* creating \e[0mtmp/my_app1/broker.ex\e[0m
      """

      assert File.exists?("tmp/my_app1/broker.ex")
      assert File.read!("tmp/my_app1/broker.ex") == """
      defmodule MyApp1.Broker do
        use Conduit.Broker, otp_app: :my_app1

        configure do
          # queue "my_app1.queue"
        end

        # pipeline :in_tracking do
        #   plug Conduit.Plug.CorrelationId
        #   plug Conduit.Plug.LogIncoming
        # end

        # pipeline :error_handling do
        #   plug Conduit.Plug.DeadLetter, broker: MyApp1.Broker, publish_to: :error
        #   plug Conduit.Plug.Retry, attempts: 5
        # end

        # pipeline :deserialize do
        #   plug Conduit.Plug.Decode, content_encoding: "gzip"
        #   plug Conduit.Plug.Parse, content_type: "application/json"
        # end

        incoming MyApp1 do
          # subscribe :my_subscription, MySubscriber, from: "my_app1.queue"
        end

        # pipeline :out_tracking do
        #   plug Conduit.Plug.CorrelationId
        #   plug Conduit.Plug.CreatedBy, app: "my_app1"
        #   plug Conduit.Plug.CreatedAt
        #   plug Conduit.Plug.LogOutgoing
        # end

        # pipeline :serialize do
        #   plug Conduit.Plug.Format, content_type: "application/json"
        #   plug Conduit.Plug.Encode, content_encoding: "gzip"
        # end

        # pipeline :error_destination do
        #   plug :put_destination, &(&1.source <> ".error")
        # end

        outgoing do
          # pipe_through [:out_tracking, :serialize]

          # publish :my_event, to: "my_app1.my_event"
        end

        # outgoing do
        #   pipe_through [:error_destination, :out_tracking, :serialize]

        #   publish :error, exchange: "amq.topic"
        # end
      end
      """
    end
  end
end
