defmodule Conduit.Broker do
  @moduledoc """
  A broker is a declarative description of your external message broker (i.e. RabbitMQ, SQS, etc).

  You can create a broker by using `Conduit.Broker` in a module.

      defmodule MyApp.Broker do
        use Conduit.Broker, otp_app: :my_app
      end

  The `:otp_app` option is required, so that your broker can find it's configuration. In this example, it would be
  expected to be defined like so:

      config :my_app, MyApp.Broker, [] # adapter options...

  ## Topology

  The topology is a
  description of the primitives that need to exist on your broker before the application can publish and receive
  messages. In really simple brokers, this may just mean defining the queues that need to exist. In more complex
  brokers, you may need to define other things like exchanges. You will need to understand what your specific broker
  supports

  The topology for your broker can be defined in the `Conduit.Broker.DSL.configure/1` block.

      defmodule MyApp.Broker do
        use Conduit.Broker, otp_app: :my_app

        configure do
        end
      end
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("broker expects :otp_app to be given")
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app
      import Conduit.Plug.MessageActions

      @type route :: atom
      @type message :: Conduit.Message.t()
      @type opts :: Keyword.t()
      @type next :: (Conduit.Message.t() -> Conduit.Message.t())
      @type pipeline :: atom

      @callback pipelines() :: [Conduit.Pipeline.t()]
      @callback pipeline(message, next, pipeline) :: message | no_return
      @callback publish(message, route, opts) :: message | no_return
      @callback publish(message, route) :: message | no_return
      @callback receives(route, message) :: message | no_return

      @doc false
      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, [opts], name: __MODULE__)
      end

      @doc false
      def child_spec(args) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, args},
          type: :supervisor
        }
      end

      @doc false
      def init([_opts]) do
        Conduit.Broker.init(@otp_app, __MODULE__, topology(), subscribe_routes())
      end
    end
  end

  @doc false
  def init(otp_app, broker, topology, subscribe_routes) do
    config = Application.get_env(otp_app, broker, [])
    adapter = Keyword.get(config, :adapter) || raise Conduit.AdapterNotConfiguredError

    subscribers =
      Map.new(subscribe_routes, fn route ->
        {route.name, route.opts}
      end)

    topology =
      Enum.map(topology, fn
        %Conduit.Topology.Exchange{} = exchange -> {:exchange, exchange.name, exchange.opts}
        %Conduit.Topology.Queue{} = queue -> {:queue, queue.name, queue.opts}
      end)

    children = [
      {adapter, [broker, topology, subscribers, config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def raw_publish(otp_app, broker, message, opts) do
    config = Application.get_env(otp_app, broker)
    adapter = Keyword.get(config, :adapter)

    adapter.publish(broker, message, config, opts)
  end
end
