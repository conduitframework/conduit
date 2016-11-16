defmodule Conduit.Format.Json do
  use Conduit.Format

  @doc """
  Encodes the message body to json
  """
  def encode(message, _opts) do
    message
    |> put_body(Poison.encode!(message.body))
    |> put_meta(:content_type, "application/json")
  end

  def decode(message, _opts) do
    message
    |> put_body(Poison.decode!(message))
  end
end
