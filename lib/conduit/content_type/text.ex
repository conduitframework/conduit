defmodule Conduit.ContentType.Text do
  use Conduit.ContentType

  @moduledoc """
  Handles converting a message body to and from Text.
  """

  @doc """
  Formats the message body to text.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("my message")
      iex>   |> Conduit.ContentType.Text.format([])
      iex> message.body
      "my message"

  """
  def format(message, _opts) do
    put_body(message, to_string(message.body))
  end

  @doc """
  Parses the body from text.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("my message")
      iex>   |> Conduit.ContentType.Text.parse([])
      iex> message.body
      "my message"

  """
  def parse(message, _opts) do
    message
  end
end
