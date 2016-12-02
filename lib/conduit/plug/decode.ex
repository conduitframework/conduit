defmodule Conduit.Plug.Decode do
  use Conduit.Plug.Builder
  @moduledoc """
  Decodes the message body based on the content encoding.

  It uses in order of preference:

    1. The content encoding specified for the plug.
    2. The content encoding specified on the message.
    3. The default content encoding `identity`.

  This plug should be used in an incoming pipeline. Generally before
  a `Conduit.Plug.Parse` plug.

      plug Conduit.Plug.Decode
      plug Conduit.Plug.Decode, content_encoding: "gzip"

  """

  @doc """
  Formats the message body based on the content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Decode.run
      iex> message.body
      "{}"
      iex> message.content_encoding
      "identity"
  """
  @default_content_encoding "identity"
  def call(message, next, opts) do
    content_encoding =
      Keyword.get(opts, :content_encoding)
      || Map.get(message, :content_encoding)
      || @default_content_encoding

    message
    |> Conduit.Encoding.decode(content_encoding, opts)
    |> next.()
  end
end
