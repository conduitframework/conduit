defmodule Conduit.Plug.AckException do
  use Conduit.Plug.Builder
  require Logger
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
  rescue error ->
    formatted_error = Exception.format(:error, error)

    Logger.warn(["Ignoring raised exception because exceptions are set to be acked\n", formatted_error])

    ack(message)
  end
end
