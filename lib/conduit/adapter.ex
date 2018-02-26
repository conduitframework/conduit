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
              {:ok, Conduit.Message.t()} | {:error, binary | atom}

  @doc """
  Defines the `use`ing module as implementing the `Conduit.Adapter` behavior.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Adapter
    end
  end
end
