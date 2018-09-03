defmodule Mix.Tasks.Conduit.Gen.Broker do
  use Mix.Task
  import Mix.Generator
  import Mix.Shell.IO

  @shortdoc "Generates a broker for sending and receiving messages"
  @moduledoc """
  Generates a broker for sending and receiving messages.

      mix conduit.gen.broker [--adapter ADAPTER] [--module BROKER_MODULE]

  ## Command line options
    * `--adapter` - The adapter that the broker will be configured to use.
                    Supported options are `sqs` and `amqp`.
    * `--module`  - The name of the broker module. The namespace determines the
                    location that the file is generated in.

  The generated files will contain:

    * a broker in lib/my_app_queue/

  """

  @doc false
  def run(args) do
    {switches, _} = OptionParser.parse!(args, strict: [module: :string, adapter: :string])

    app = get_app()
    module = get_module(switches[:module], app)
    parent_module = get_parent_module(module)
    path = get_path(parent_module)
    file = get_file(module)
    adapter = get_adapter(switches[:adapter])

    assigns = [
      path: path,
      file: file,
      parent_module: parent_module,
      module: module,
      app: app,
      adapter: adapter
    ]

    create_broker(assigns)
  end

  defp get_app do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> to_string()
  end

  defp get_module(nil, app) do
    Macro.camelize(app) <> "Queue.Broker"
  end

  defp get_module(module, _), do: module

  defp get_parent_module(module) do
    module
    |> String.split(".")
    |> List.delete_at(-1)
    |> Enum.join(".")
  end

  defp get_path(parent_module) do
    Path.join([base_path(), Macro.underscore(parent_module)])
  end

  defp base_path do
    :conduit
    |> Application.get_env(Mix.Tasks.Conduit.Gen.Broker, [])
    |> Keyword.get(:lib_path, "lib")
  end

  defp get_file(module) do
    module
    |> String.split(".")
    |> Enum.at(-1)
    |> Macro.underscore()
    |> Kernel.<>(".ex")
  end

  defp get_adapter(adapter) when adapter in [nil, "amqp"], do: "conduit_amqp"
  defp get_adapter("sqs"), do: "conduit_sqs"

  defp create_broker(assigns) do
    create_directory(assigns[:path])

    broker_file = Path.join([assigns[:path], assigns[:file]])
    create_file(broker_file, broker_template(assigns))
    info(broker_info_template(assigns))
  end

  embed_template(:broker, """
  defmodule <%= @module %> do
    use Conduit.Broker, otp_app: :<%= @app %>
  <%= case @adapter do %>
  <% "conduit_sqs" -> %>
    configure do
      # queue "<%= @app %>-queue"
      # queue "<%= @app %>-queue-error"
    end
  <% "conduit_amqp" -> %>
    configure do
      # queue "<%= @app %>.queue"
    end
  <% end %>
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
  <%= case @adapter do %>
  <% "conduit_sqs" -> %>
    incoming <%= @parent_module %> do
      # subscribe :my_subscription, MySubscriber, from: "<%= @app %>-queue"
    end
  <% "conduit_amqp" -> %>
    incoming <%= @parent_module %> do
      # subscribe :my_subscription, MySubscriber, from: "<%= @app %>.queue"
    end
  <% end %>
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
  <%= case @adapter do %>
  <% "conduit_sqs" -> %>
    # pipeline :error_destination do
    #   plug :put_destination, &(&1.source <> "-error")
    # end

    outgoing do
      # pipe_through [:out_tracking, :serialize]

      # publish :my_event, to: "<%= @app %>-my-event"
    end

    # outgoing do
    #   pipe_through [:error_destination, :out_tracking, :serialize]

    #   publish :error
    # end
  <% "conduit_amqp" -> %>
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
  <% end %>
  end
  """)

  embed_template(:broker_info, """
  <%= case @adapter do %>
  <% "conduit_sqs" -> %>
  Add conduit_sqs to your dependencies in mix.exs:

      {:conduit_sqs, "~> 0.1"}

  Make sure to add the following to your config.exs:

      config :<%= @app %>, <%= @module %>,
        adapter: ConduitSQS,
        access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
        secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]
  <% "conduit_amqp" -> %>
  Add conduit_amqp to your dependencies in mix.exs:

      {:conduit_amqp, "~> 0.4"}

  Make sure to add the following to your config.exs:

      config :<%= @app %>, <%= @module %>,
        adapter: ConduitAMQP,
        url: "amqp://guest:guest@localhost:6782"
  <% end %>
  Also, add your broker to the supervision hierarchy in your <%= @app %>.ex:

  Elixir v1.5 or above:

      def start(_type, _args) do
        children = [
          # ...
          {<%= @module %>, []}
        ]

        opts = [strategy: :one_for_one]

        Supervisor.start_link(children, opts)
      end

  Elixir v1.4 or below:

      def start(_type, _args) do
        children = [
          # ...
          supervisor(<%= @module %>, [])
        ]

        supervise(children, strategy: :one_for_one)
      end
  """)
end
