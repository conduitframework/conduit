defmodule Conduit.Encoding.Identity do
  use Conduit.Encoding

  @moduledoc """
  Does nothing to the body of the message.
  """

  @doc """
  Does nothing to the body.

  ## Examples

      iex> Conduit.Encoding.Identity.encode("{}", [])
      "{}"

  """
  def encode(message, _opts) do
    message
  end

  @doc """
  Does nothing to the body.

  ## Examples

      iex> Conduit.Encoding.Identity.decode("{}", [])
      "{}"

  """
  def decode(message, _opts) do
    message
  end
end
