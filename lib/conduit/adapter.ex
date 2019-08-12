defmodule Conduit.Adapter do
  @moduledoc """
  Defines the behavior for an adapter.
  """

  @type topology :: [{atom, binary, Keyword.t()}]
  @type subscribers :: %{atom => {module, Keyword.t()}}
  @type opts :: Keyword.t()

  @callback start_link(Conduit.Broker.t(), topology, subscribers, Conduit.Config.t()) :: GenServer.on_start()

  @callback publish(Conduit.Message.t(), Conduit.Config.t(), opts) ::
              {:ok, Conduit.Message.t()} | {:error, binary | atom} | no_return
  @callback publish(module, Conduit.Message.t(), Conduit.Config.t(), opts) ::
              {:ok, Conduit.Message.t()} | {:error, term}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Adapter

      @impl true
      def publish(message, config, opts) do
        raise RuntimeError, "#{__MODULE__} should implement Conduit.Adapter.publish/4 callback."
      end

      @impl true
      def publish(broker, message, config, opts) do
        require Logger

        Logger.warn("#{__MODULE__}.publish/3 is deprecated. Adapter should implement #{__MODULE__}.publish/4 instead.")

        publish(message, config, opts)
      end

      defoverridable publish: 3, publish: 4
    end
  end
end
