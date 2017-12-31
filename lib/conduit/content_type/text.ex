defmodule Conduit.ContentType.Text do
  use Conduit.ContentType
  @moduledoc """
  Handles converting a message body to and from Text.
  """

  @doc """
  Formats the message body to text.

  ## Examples

      iex> Conduit.ContentType.Text.format("my message", [])
      "my message"

  """
  def format(body, _opts) do
    to_string(body)
  end

  @doc """
  Parses the body from text.

  ## Examples

      iex> Conduit.ContentType.Text.parse("my message", [])
      "my message"

  """
  def parse(body, _opts) do
    body
  end
end
