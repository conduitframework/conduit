defmodule Conduit.Plug.AckException do
  use Conduit.Plug.Builder
  @moduledoc """
  Rescues any exception and acks the message.

  Options are ignored.

  ## Examples

      plug Conduit.Plug.AckException

  """

  @doc """
  Rescues any exception and acks the message.
  """
  def call(message, next, _opts) do
    next.(message)
  rescue _ ->
    ack(message)
  end
end
