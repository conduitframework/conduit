defmodule Conduit.ContentType.JSON do
  use Conduit.ContentType
  @moduledoc """
  Handles converting to and from JSON.
  """

  @doc """
  Formats the body to json.

  ## Examples

      iex> Conduit.ContentType.JSON.format(%{}, [])
      "{}"

  """
  def format(body, opts) do
    Poison.encode!(body, opts)
  end

  @doc """
  Parses the body from json.

  ## Examples

      iex> Conduit.ContentType.JSON.parse("{}", [])
      %{}

  """
  def parse(body, opts) do
    Poison.decode!(body, opts)
  end
end
