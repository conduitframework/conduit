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

  alias Conduit.Config

  @type t :: module
  @type route :: atom
  @type message :: Conduit.Message.t()
  @type opts :: Keyword.t()
  @type next :: (Conduit.Message.t() -> Conduit.Message.t())
  @type config :: Keyword.t()
  @type pipeline :: atom
  @typep args :: [] | [opts]

  @callback pipelines() :: [Conduit.Pipeline.t()]
  @callback pipeline(message, next, pipeline) :: message | no_return
  @callback publish(message, route, opts) :: message | no_return
  @callback receives(route, message) :: message | no_return
  @callback get_config(Config.postfix()) :: Config.config()

  @doc false
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("broker expects :otp_app to be given")
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app
      import Conduit.Plug.MessageActions
      @behaviour unquote(__MODULE__)

      @doc false
      def start_link(opts \\ []) do
        unquote(__MODULE__).start_link(@otp_app, __MODULE__, opts)
      end

      @doc false
      def child_spec(args) do
        unquote(__MODULE__).child_spec(@otp_app, __MODULE__, args)
      end

      @doc false
      @impl true
      def init([opts]) do
        unquote(__MODULE__).init(@otp_app, __MODULE__, opts)
      end

      @impl true
      def get_config(postfix \\ nil) do
        unquote(__MODULE__).get_config(__MODULE__, postfix)
      end
    end
  end

  @doc false
  @spec start_link(Config.otp_app(), t, opts) :: Supervisor.on_start()
  def start_link(otp_app, broker, opts) do
    Supervisor.start_link(broker, [opts], name: name(otp_app, broker, opts))
  end

  @doc false
  @spec child_spec(Config.otp_app(), t, args) :: Supervisor.child_spec()
  def child_spec(otp_app, broker, []), do: child_spec(otp_app, broker, [[]])

  def child_spec(otp_app, broker, [opts]) do
    %{
      id: name(otp_app, broker, opts),
      start: {broker, :start_link, [opts]},
      type: :supervisor
    }
  end

  @doc false
  @spec init(Config.otp_app(), t, opts) :: {:ok, tuple()}
  def init(otp_app, broker, opts) do
    config = Config.new(otp_app, broker, opts)
    adapter = Keyword.get(config, :adapter) || raise Conduit.AdapterNotConfiguredError

    children = [
      {adapter, [broker, get_topology(broker, config), get_subscribers(broker, config), config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_topology(broker, config) do
    config
    |> broker.topology()
    |> Enum.map(fn
      %Conduit.Topology.Exchange{} = exchange -> {:exchange, exchange.name, exchange.opts}
      %Conduit.Topology.Queue{} = queue -> {:queue, queue.name, queue.opts}
    end)
  end

  defp get_subscribers(broker, config) do
    config
    |> broker.subscribe_routes()
    |> Map.new(fn route ->
      {route.name, route.opts}
    end)
  end

  @doc false
  @spec get_config(atom(), atom()) :: keyword()
  def get_config(broker, postfix) do
    Config.get(broker, postfix)
  end

  @doc false
  def raw_publish(broker, message, opts) do
    route_opts = Conduit.Message.get_private(message, :opts)
    config = Conduit.Message.get_private(message, :broker_config)
    adapter = Keyword.get(config, :adapter)

    adapter.publish(broker, message, config, Keyword.merge(route_opts, opts))
  end

  defp name(otp_app, broker, opts) do
    config = Config.apply(otp_app, broker, opts)
    Conduit.broker_name(broker, config)
  end
end
