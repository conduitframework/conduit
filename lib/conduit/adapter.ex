defmodule Conduit.Adapter do
  @moduledoc """
  Defines the behavior for an adapter.
  """

  @type setup :: [{atom, binary, Keyword.t}]
  @type subscribers :: %{atom => {module, Keyword.t}}

  @callback start_link(setup, subscribers, Keyword.t) :: pid
  @callback publish(Conduit.Message.t, Keyword.t) :: {:ok, Conduit.Message.t} | {:error, binary}

  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Adapter
    end
  end
end
