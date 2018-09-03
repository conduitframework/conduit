defmodule Mix.Tasks.Conduit.Gen.Subscriber do
  use Mix.Task
  import Mix.Generator
  import Mix.Shell.IO

  @shortdoc "Generates a subscriber for messages"
  @moduledoc """
  Generates a subscriber for messages.

      mix conduit.gen.subscriber NAME [--broker BROKER_MODULE]

  Accepts the module name for the subscriber.

  ## Command line options
    * `--broker` - The broker that will use this subscriber. This defaults to
                   `AppNameQueue.Broker`. You can override the directory that
                   files are created in by specifying a different broker module.

  The generated files will contain:

    * a subscriber in lib/my_app_queue/subscribers
    * a subscriber_test in test/my_app_queue/subscribers

  """

  @doc false
  def run(args) do
    {switches, argv} = OptionParser.parse!(args, strict: [broker: :string])

    case argv do
      [] ->
        raise ArgumentError, "name is a required argument"

      [name | _] ->
        app = get_app()
        name = Macro.underscore(name)

        broker_module = get_broker_module(switches[:broker])
        adapter = get_adapter(broker_module)
        subscriber_name = get_subscriber_name(name)
        parent_module = get_parent_module(broker_module)
        queue_name = get_queue_name(adapter, app, name)
        path = get_path(parent_module, lib_path())
        file = get_file(name)
        test_path = get_path(parent_module, test_path())
        test_file = get_file(name, "_subscriber_test.exs")

        assigns = [
          app: app,
          adapter: adapter,
          name: name,
          subscriber_name: subscriber_name,
          queue_name: queue_name,
          parent_module: parent_module,
          broker_module: broker_module,
          path: path,
          file: file,
          test_path: test_path,
          test_file: test_file
        ]

        create_subscriber(assigns)
    end
  end

  defp create_subscriber(assigns) do
    create_directory(assigns[:path])

    subscriber_file = Path.join([assigns[:path], assigns[:file]])
    create_file(subscriber_file, subscriber_template(assigns))

    subscriber_test_file = Path.join([assigns[:test_path], assigns[:test_file]])
    create_file(subscriber_test_file, subscriber_test_template(assigns))

    info(subscriber_info_template(assigns))
  end

  defp get_app do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> to_string()
  end

  defp get_adapter(broker_module) do
    broker = Module.concat([broker_module])

    Mix.Project.config()
    |> Keyword.get(:app)
    |> Application.get_env(broker)
    |> case do
      nil ->
        raise ArgumentError, """
        #{broker_module} is not configured. To configure your broker, see
        https://hexdocs.pm/conduit/readme.html#getting-started
        """

      config ->
        config
    end
    |> Keyword.get(:adapter)
    |> case do
      ConduitSQS ->
        :sqs

      ConduitAMQP ->
        :amqp

      _ ->
        raise ArgumentError, """
        #{broker_module} is not configured with an adapter. To configure your broker, see
        https://hexdocs.pm/conduit/readme.html#getting-started
        """
    end
  end

  defp get_broker_module(nil) do
    get_app()
    |> Kernel.<>("_queue/broker")
    |> Macro.camelize()
  end

  defp get_broker_module(broker_module) do
    broker_module
  end

  defp get_parent_module(broker_module) do
    broker_module
    |> String.split(".")
    |> List.delete_at(-1)
    |> Enum.join(".")
  end

  defp get_queue_name(:sqs, app, name) do
    String.replace("#{app}-#{name}", ~r<[/_.]>, "-")
  end

  defp get_queue_name(_, app, name) do
    String.replace("#{app}.#{name}", ~r<[/]>, ".")
  end

  defp get_subscriber_name(name) do
    Macro.camelize(name) <> "Subscriber"
  end

  defp get_path(parent_module, base_path) do
    Path.join([base_path, Macro.underscore(parent_module), "subscribers"])
  end

  defp lib_path do
    :conduit
    |> Application.get_env(Mix.Tasks.Conduit.Gen.Broker, [])
    |> Keyword.get(:lib_path, "lib")
  end

  defp test_path do
    :conduit
    |> Application.get_env(Mix.Tasks.Conduit.Gen.Broker, [])
    |> Keyword.get(:test_path, "test")
  end

  defp get_file(name, postfix \\ "_subscriber.ex") do
    name
    |> Macro.underscore()
    |> Kernel.<>(postfix)
  end

  embed_template(:subscriber, """
  defmodule <%= @parent_module %>.<%= @subscriber_name %> do
    use Conduit.Subscriber

    def process(message, _opts) do
      # Code to process the message

      message
    end
  end
  """)

  embed_template(:subscriber_test, """
  defmodule <%= @parent_module %>.<%= @subscriber_name %>Test do
    use ExUnit.Case
    use Conduit.Test
    import Conduit.Message
    alias Conduit.Message
    alias <%= @parent_module %>.<%= @subscriber_name %>

    describe "process/2" do
      test "returns acked message" do
        message =
          %Message{}
          |> put_body("foo")

        assert %Message{status: :ack} = <%= @subscriber_name %>.run(message)
      end
    end
  end
  """)

  embed_template(:subscriber_info, """

  In an incoming block in your <%= @broker_module %> add:

      subscribe :<%= @name %>, <%= @subscriber_name %>, from: "<%= @queue_name %>"

  You may also want to define the queue in the configure block for <%= @broker_module %>:

      queue "<%= @queue_name %>"
  """)
end
