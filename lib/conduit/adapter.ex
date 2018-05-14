defmodule Conduit.Adapter do
  @moduledoc """
  Defines the behavior for an adapter.
  """

  @type broker :: module
  @type topology :: [{atom, binary, Keyword.t()}]
  @type subscribers :: %{atom => {module, Keyword.t()}}
  @type config :: Keyword.t()
  @type opts :: Keyword.t()

  @callback start_link(broker, topology, subscribers, config) :: GenServer.on_start()

  @callback publish(Conduit.Message.t(), config, opts) ::
              {:ok, Conduit.Message.t()} | {:error, binary | atom} | no_return
  @callback publish(module, Conduit.Message.t(), config, opts) :: {:ok, Conduit.Message.t()} | {:error, term}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Adapter

      def publish(message, config, opts) do
        raise RuntimeError, "#{__MODULE__} should implement Conduit.Adapter.publish/4 callback."
      end

      def publish(broker, message, config, opts) do
        require Logger

        Logger.warn("#{__MODULE__}.publish/3 is deprecated. Adapter should implement #{__MODULE__}.publish/4 instead.")

        publish(message, config, opts)
      end

      defoverridable publish: 3, publish: 4
    end
  end
end
