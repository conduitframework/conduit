defmodule Conduit.ContentType.Text do
  use Conduit.ContentType
  @moduledoc """
  Handles converting a message body to and from Text.
  """

  @doc """
  Formats the message body to json and sets the content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("my message")
      iex>   |> Conduit.ContentType.Text.format([])
      iex> message.body
      "my message"
      iex> message.content_type
      "text/plain"

  """
  def format(message, _opts) do
    message
    |> put_content_type("text/plain")
  end

  @doc """
  Parses the message body from json and sets the content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("my message")
      iex>   |> Conduit.ContentType.Text.parse([])
      iex> message.body
      "my message"
      iex> message.content_type
      "text/plain"

  """
  def parse(message, _opts) do
    message
    |> put_content_type("text/plain")
  end
end
