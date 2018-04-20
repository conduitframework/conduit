defmodule Conduit.Plug.MessageId do
  use Conduit.Plug.Builder
  require Logger

  @moduledoc """
  Assigns a UUID for the message ID of the message if one isn't present and always assigns
  it to the logger metadata.

  ## Examples

      plug Conduit.Plug.MessageId

      iex> message = Conduit.Plug.MessageId.run(%Conduit.Message{})
      iex> message.message_id == Logger.metadata[:message_id]
      true

  """

  @doc """
  Assigns a UUID for the message ID of the message if one isn't present and always assigns
  it to the logger metadata.
  """
  def call(message, next, _opts) do
    message
    |> put_new_message_id(UUID.uuid4())
    |> put_logger_metadata
    |> next.()
  end

  defp put_logger_metadata(message) do
    Logger.metadata(message_id: message.message_id)

    message
  end
end
