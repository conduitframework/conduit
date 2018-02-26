defmodule Conduit.Plug.NackException do
  use Conduit.Plug.Builder

  @moduledoc """
  Rescues any exception and nacks the message.

  Options are ignored.

  ## Examples

      plug Conduit.Plug.NackException

  """

  @doc """
  Rescues any exception and nacks the message.
  """
  def call(message, next, _opts) do
    next.(message)
  rescue
    _ ->
      nack(message)
  end
end
