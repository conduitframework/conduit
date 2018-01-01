defmodule Conduit.ContentType.ErlangBinary do
  use Conduit.ContentType
  @moduledoc """
  Handles converting to and from erlang binary.
  """

  @doc """
  Formats the body to erlang binary.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> Conduit.ContentType.ErlangBinary.format([compressed: 6])
      iex> :erlang.binary_to_term(message.body)
      %{}

  """
  def format(message, opts) do
    put_body(message, :erlang.term_to_binary(message.body, opts))
  end

  @doc """
  Parses the body from erlang binary.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(<<131, 116, 0, 0, 0, 0>>)
      iex>   |> Conduit.ContentType.ErlangBinary.parse([])
      iex> message.body
      %{}

  """
  def parse(message, opts) do
    put_body(message, :erlang.binary_to_term(message.body, opts))
  end
end
