defmodule Mix.Tasks.Conduit.Gen.Broker do
  use Mix.Task
  import Mix.Generator
  import Mix.Shell.IO

  @doc """

  mix conduit.gen.broker my_app/blah -a conduit_sqs or conduit_amqp -m MyApp.Broker
  mix conduit.gen.broker PATH [--adapter ADAPTER] [--app APP] [--module MODULE]
  """
  def run(args) do
    {switches, argv} =
      OptionParser.parse!(args, strict: [app: :string, module: :string, adapter: :string])

    case argv do
      [] ->
        raise "hell"
      [path | _] ->
        app = get_app(switches[:app], path)
        module = get_module(switches[:module], app)
        parent_module = get_parent_module(module)
        adapter = get_adapter(switches[:adapter])

        assigns = [path: path, parent_module: parent_module, module: module, app: app, adapter: adapter]

        create_broker(assigns)
    end
  end

  defp get_app(nil, path) do
    path
    |> Path.expand()
    |> Path.basename()
  end
  defp get_app(app, _), do: app

  defp get_module(nil, app) do
    Macro.camelize(app) <> ".Broker"
  end
  defp get_module(module, _), do: module

  defp get_parent_module(module) do
    module
    |> String.split(".")
    |> List.delete_at(-1)
    |> Enum.join(".")
  end

  defp get_adapter(adapter) when adapter in [nil, "conduit_amqp"], do: "conduit_amqp"
  defp get_adapter("conduit_sqs" = adapter), do: adapter

  defp create_broker(assigns) do
    create_directory(assigns[:path])

    broker_file = Path.join([assigns[:path], "broker.ex"])
    create_file(broker_file, broker_template(assigns))
    info """

    Make sure to add the following to your config.exs:

        config :#{assigns[:app]}, #{assigns[:module]},
          url: "amqp://guest:guest@localhost:6782"

    Also, add your broker to the supervision hierarchy in your #{assigns[:app]}.ex:

        def start(_type, _args) do
          children = [
            # ...
            supervisor(#{assigns[:module]}, [])
          ]

          supervise(children, strategy: :one_for_one)
        end
    """
  end

  embed_template :broker, """
  defmodule <%= @module %> do
    use Conduit.Broker, otp_app: :<%= @app %>

    configure do
      # queue "<%= @app %>.queue"
    end

    # pipeline :in_tracking do
    #   plug Conduit.Plug.CorrelationId
    #   plug Conduit.Plug.LogIncoming
    # end

    # pipeline :error_handling do
    #   plug Conduit.Plug.DeadLetter, broker: <%= @module %>, publish_to: :error
    #   plug Conduit.Plug.Retry, attempts: 5
    # end

    # pipeline :deserialize do
    #   plug Conduit.Plug.Decode, content_encoding: "gzip"
    #   plug Conduit.Plug.Parse, content_type: "application/json"
    # end

    incoming <%= @parent_module %> do
      # subscribe :my_subscription, MySubscriber, from: "<%= @app %>.queue"
    end

    # pipeline :out_tracking do
    #   plug Conduit.Plug.CorrelationId
    #   plug Conduit.Plug.CreatedBy, app: "<%= @app %>"
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

      # publish :my_event, to: "<%= @app %>.my_event"
    end

    # outgoing do
    #   pipe_through [:error_destination, :out_tracking, :serialize]

    #   publish :error, exchange: "amq.topic"
    # end
  end
  """
end
