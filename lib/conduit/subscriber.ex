defmodule Conduit.Subscriber do
  @moduledoc """
  Provides functions and macros for handling incoming messages
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Conduit.Plug.Builder
    end
  end
end
