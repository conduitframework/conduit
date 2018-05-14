defmodule Conduit.Broker do
  @moduledoc """
  Defines a Conduit Broker.

  The broker is the boundary between your application and a
  message queue. It allows the setup of a message queue and
  provides a DSL for handling incoming messages and outgoing
  messages.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("endpoint expects :otp_app to be given")
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app

      @type route :: atom
      @type message :: Conduit.Message.t()
      @type opts :: Keyword.t()

      @callback publish(route, message, opts) :: message | no_return
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
        Conduit.Broker.init(@otp_app, __MODULE__, topology_config(), subscribers())
      end
    end
  end

  @doc false
  def init(otp_app, broker, topology, subscribers) do
    config = Application.get_env(otp_app, broker, [])
    adapter = Keyword.get(config, :adapter) || raise Conduit.AdapterNotConfiguredError

    subs =
      subscribers
      |> Enum.map(fn {name, {_, opts}} ->
        {name, opts}
      end)
      |> Enum.into(%{})

    children = [
      {adapter, [broker, topology, subs, config]}
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
