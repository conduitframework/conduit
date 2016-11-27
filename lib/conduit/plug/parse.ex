defmodule Conduit.Plug.Parse do
  use Conduit.Plug.Builder
  @moduledoc """
  Parses the message body based on the content type.

  It uses in order of preference:

    1. The content type specified for the plug.
    2. The content type specified on the message.
    3. The default content type `text/plain`.

  This plug should be used in an incoming pipeline.

      plug Conduit.Plug.Parse
      plug Conduit.Plug.Parse, content_type: "application/json"

  """

  @doc """
  Formats the message body based on the content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Parse.call(content_type: "application/json")
      iex> message.body
      %{}
      iex> message.content_type
      "application/json"
  """
  @default_content_type "text/plain"
  def call(message, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || Map.get(message, :content_type)
      || @default_content_type

    Conduit.ContentType.parse(message, content_type, opts)
  end
end
