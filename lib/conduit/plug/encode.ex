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

      plug Conduit.Plug.Encode
      plug Conduit.Plug.Encode, content_encoding: "gzip"

  """

  @doc """
  Encodes the message body based on the content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Encode.call([])
      iex> message.body
      "{}"
      iex> get_meta(message, :content_encoding)
      "identity"
  """
  @default_content_encoding "identity"
  def call(message, opts) do
    content_encoding =
      Keyword.get(opts, :content_encoding)
      || get_meta(message, :content_encoding)
      || @default_content_encoding

    Conduit.Encoding.encode(message, content_encoding, opts)
  end
end
