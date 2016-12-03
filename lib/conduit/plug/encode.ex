defmodule Conduit.Plug.Encode do
  use Conduit.Plug.Builder
  @moduledoc """
  Encodes the message body based on the content encoding.

  It uses in order of preference:

    1. The content encoding specified for the plug.
    2. The content encoding specified on the message.
    3. The default content encoding `identity`.

  This plug should be used in an outgoing pipeline. Generally after
  a `Conduit.Plug.Format` plug.

  ## Examples

      plug Conduit.Plug.Encode
      plug Conduit.Plug.Encode, content_encoding: "gzip"

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Encode.run
      iex> message.body
      "{}"
      iex> message.content_encoding
      "identity"

  """

  @doc """
  Encodes the message body based on the content encoding.
  """
  @default_content_encoding "identity"
  def call(message, next, opts) do
    content_encoding =
      Keyword.get(opts, :content_encoding)
      || Map.get(message, :content_encoding)
      || @default_content_encoding

    message
    |> Conduit.Encoding.encode(content_encoding, opts)
    |> next.()
  end
end
