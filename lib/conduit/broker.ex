defmodule Conduit.Broker do
  @moduledoc """
  Defines a Conduit Broker.

  The broker is the boundary between your application and a
  message queue. It allows the setup of a message queue and
  provides a DSL for handling incoming messages and outgoing
  messages.
  """

  @doc """
  Sets the broker up as a `Supervisor` and includes the
  `Conduit.Broker.DSL`.
  """
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "endpoint expects :otp_app to be given"
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(_opts) do
        import Supervisor.Spec

        config = Application.get_env(@otp_app, __MODULE__)
        adapter =
          Keyword.get(config, :adapter)
          || raise Conduit.AdapterNotConfiguredError

        subs =
          subscribers()
          |> Enum.map(fn {name, {_, opts}} ->
            {name, opts}
          end)
          |> Enum.into(%{})

        children = [supervisor(adapter, [
          __MODULE__,
          topology(),
          subs,
          config
        ])]

        supervise(children, strategy: :one_for_one)
      end
    end
  end
end
