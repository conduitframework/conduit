defmodule Conduit.Plug.CorrelationId do
  use Conduit.Plug.Builder
  require Logger

  @moduledoc """
  Assigns a UUID for the correlation ID of the message if one isn't present and always assigns
  it to the logger metadata.

  ## Examples

      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.CorrelationId
      iex> end
      iex>
      iex> message = MyPipeline.run(%Conduit.Message{})
      iex> message.correlation_id == Logger.metadata[:correlation_id]
      true

  """

  @doc """
  Assigns a UUID for the correlation ID of the message if one isn't present and always assigns
  it to the logger metadata.
  """
  def call(message, next, _opts) do
    message
    |> put_new_correlation_id(UUID.uuid4())
    |> put_logger_metadata
    |> next.()
  end

  defp put_logger_metadata(message) do
    Logger.metadata(correlation_id: message.correlation_id)

    message
  end
end
