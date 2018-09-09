defmodule Conduit.Plug.AckException do
  use Conduit.Plug.Builder
  require Logger

  @moduledoc """
  Rescues any exception and acks the message.

  Options are ignored.

  ## Examples

    iex> defmodule MyPipeline do
    iex>   use Conduit.Plug.Builder
    iex>   plug Conduit.Plug.AckException
    iex>
    iex>   def call(_message, _next, _opts) do
    iex>     raise "hell"
    iex>   end
    iex> end
    iex>
    iex> log = ExUnit.CaptureLog.capture_log(fn ->
    iex>   message = MyPipeline.run(%Conduit.Message{status: :nack})
    iex>   :ack = message.status
    iex> end)
    iex> log =~ "[warn]  Ignoring raised exception because exceptions are set to be acked"
    true

  """

  @doc """
  Rescues any exception and acks the message.
  """
  def call(message, next, _opts) do
    next.(message)
  rescue
    error ->
      formatted_error = Exception.format(:error, error)

      Logger.warn([
        "Ignoring raised exception because exceptions are set to be acked\n",
        formatted_error
      ])

      ack(message)
  end
end
