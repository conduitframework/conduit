defmodule Conduit.Encoding.GZip do
  use Conduit.Encoding
  @moduledoc """
  Handles encoding a message body to and from gzip.
  """

  @doc """
  Encodes the message body to gzip and sets the content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Encoding.GZip.encode([])
      iex> message.body
      <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>
      iex> message.content_encoding
      "gzip"

  """
  def encode(message, _opts) do
    message
    |> put_body(:zlib.gzip(message.body))
    |> put_content_encoding("gzip")
  end

  @doc """
  Decodes the message body from gzip and sets the content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(<<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>)
      iex>   |> Conduit.Encoding.GZip.decode([])
      iex> message.body
      "{}"
      iex> message.content_encoding
      "gzip"

  """
  def decode(message, _opts) do
    message
    |> put_body(:zlib.gunzip(message.body))
    |> put_content_encoding("gzip")
  end
end
