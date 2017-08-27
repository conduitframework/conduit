defmodule Conduit.Plug.Parse do
  use Conduit.Plug.Builder
  @moduledoc """
  Parses the message body based on the content type.

  It uses in order of preference:

    1. The content type specified for the plug.
    2. The content type specified on the message.
    3. The default content type `text/plain`.

  This plug should be used in an incoming pipeline.

  ## Examples

      plug Conduit.Plug.Parse
      plug Conduit.Plug.Parse, content_type: "application/json"

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Plug.Parse.run(content_type: "application/json")
      iex> message.body
      %{}
      iex> message.content_type
      "application/json"

  """

  alias Conduit.ContentType

  @doc """
  Formats the message body based on the content type.
  """
  @default_content_type "text/plain"
  def call(message, next, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || Map.get(message, :content_type)
      || @default_content_type

    message
    |> ContentType.parse(content_type, opts)
    |> next.()
  end
end
