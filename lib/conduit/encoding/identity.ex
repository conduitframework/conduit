defmodule Conduit.Encoding.Identity do
  use Conduit.Encoding
  @moduledoc """
  Does nothing to the body of the message. Sets the content encoding to identity.
  """

  @doc """
  Does nothing to the body and sets the content encoding to identity.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Encoding.Identity.encode([])
      iex> message.body
      "{}"
      iex> get_meta(message, :content_encoding)
      "identity"

  """
  def encode(message, _opts) do
    message
    |> put_meta(:content_encoding, "identity")
  end

  @doc """
  Decodes the message body from gzip and sets the content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Encoding.Identity.decode([])
      iex> message.body
      "{}"
      iex> get_meta(message, :content_encoding)
      "identity"

  """
  def decode(message, _opts) do
    message
    |> put_meta(:content_encoding, "identity")
  end
end
