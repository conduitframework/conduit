defmodule Conduit.ContentType.JSON do
  use Conduit.ContentType

  @moduledoc """
  Handles converting to and from JSON.
  """

  @doc """
  Formats the body to json.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> Conduit.ContentType.JSON.format([])
      iex> message.body
      "{}"

  """
  def format(message, opts) do
    put_body(message, Jason.encode!(message.body, opts))
  end

  @doc """
  Parses the body from json.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.ContentType.JSON.parse([])
      iex> message.body
      %{}

  """
  def parse(message, opts) do
    put_body(message, Jason.decode!(message.body, opts))
  end
end
