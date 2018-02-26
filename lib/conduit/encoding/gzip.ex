defmodule Conduit.Encoding.GZip do
  use Conduit.Encoding

  @moduledoc """
  Handles encoding to and from gzip.
  """

  @doc """
  Encodes the message body to gzip.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Encoding.GZip.encode([])
      iex> :zlib.gunzip(message.body)
      "{}"

  """
  def encode(message, _opts) do
    put_body(message, :zlib.gzip(message.body))
  end

  @doc """
  Decodes the message body from gzip.

  ## Examples

      iex> import Conduit.Message
      iex> body = <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(body)
      iex>   |> Conduit.Encoding.GZip.decode([])
      iex> message.body
      "{}"

  """
  def decode(message, _opts) do
    put_body(message, :zlib.gunzip(message.body))
  end
end
