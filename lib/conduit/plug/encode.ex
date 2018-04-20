defmodule Conduit.Plug.Encode do
  use Conduit.Plug.Builder

  @moduledoc """
  Encodes the message body based on the content encoding.

  It uses in order of preference:

    1. The content encoding specified for the plug.
    2. The content encoding specified on the message.
    3. The default content encoding `identity`.

  The location of the content encoding can be changed from `content_encoding`
  to a header with the `:header` option. This is useful for having multiple
  encodings, like a transfer encoding.

  This plug should be used in an outgoing pipeline. Generally after
  a `Conduit.Plug.Format` plug.

  ## Examples

      plug Conduit.Plug.Encode
      plug Conduit.Plug.Encode, content_encoding: "gzip"
      plug Conduit.Plug.Encode, header: "transfer_encoding"

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Encode.run
      iex> message.body
      "{}"
      iex> message.content_encoding
      "identity"

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Encode.run(header: "transfer_encoding")
      iex> message.body
      "{}"
      iex> get_header(message, "transfer_encoding")
      "identity"

  """

  alias Conduit.Encoding

  @doc """
  Encodes the message body based on the content encoding.
  """
  @default_content_encoding "identity"
  def call(message, next, opts) do
    content_encoding =
      Keyword.get(opts, :content_encoding) || Map.get(message, :content_encoding) || @default_content_encoding

    message
    |> put_content_encoding_at(Keyword.get(opts, :header), content_encoding)
    |> Encoding.encode(content_encoding, opts)
    |> next.()
  end

  defp put_content_encoding_at(message, nil, content_encoding) do
    put_content_encoding(message, content_encoding)
  end

  defp put_content_encoding_at(message, header, content_encoding) do
    put_header(message, header, content_encoding)
  end
end
