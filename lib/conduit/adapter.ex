defmodule Conduit.Adapter do
  @moduledoc """
  Defines the behavior for an adapter.
  """

  @type broker :: module
  @type topology :: [{atom, binary, Keyword.t}]
  @type subscribers :: %{atom => {module, Keyword.t}}

  @callback start_link(broker, topology, subscribers, Keyword.t) :: GenServer.on_start
  @callback publish(Conduit.Message.t, Keyword.t) :: {:ok, Conduit.Message.t} | {:error, binary}

  @doc """
  Defines the `use`ing module as implementing the `Conduit.Adapter` behavior.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Adapter
    end
  end
end
