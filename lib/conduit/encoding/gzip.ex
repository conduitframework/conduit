defmodule Conduit.Encoding.GZip do
  use Conduit.Encoding
  @moduledoc """
  Handles encoding to and from gzip.
  """

  @doc """
  Encodes the message body to gzip.

  ## Examples

      iex> body = Conduit.Encoding.GZip.encode("{}", [])
      iex> :zlib.gunzip(body)
      "{}"

  """
  def encode(body, _opts) do
    :zlib.gzip(body)
  end

  @doc """
  Decodes the message body from gzip.

  ## Examples

      iex> body = <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>
      iex> Conduit.Encoding.GZip.decode(body, [])
      "{}"

  """
  def decode(body, _opts) do
    :zlib.gunzip(body)
  end
end
