defmodule Conduit.Plug.CorrelationId do
  use Conduit.Plug.Builder
  @moduledoc """
  Assigns a UUID for the correlation ID of the message if one isn't present and always assigns
  it to the logger metadata.

      plug Conduit.Plug.CorrelationId

  """

  @doc """
  Assigns a UUID for the correlation ID of the message if one isn't present and always assigns
  it to the logger metadata.

  ## Examples

      iex> require Logger
      iex> message = %Conduit.Message{}
      iex> message = Conduit.Plug.CorrelationId.call(message, [])
      iex> message.correlation_id == Logger.metadata[:correlation_id]
      true
  """
  @spec call(Conduit.Message.t, any) :: Conduit.Message.t
  def call(message, _opts) do
    message
    |> put_new_correlation_id(UUID.uuid4)
    |> put_logger_metadata
  end

  defp put_logger_metadata(message) do
    Logger.metadata(correlation_id: message.correlation_id)

    message
  end
end
