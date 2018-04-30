defmodule Conduit.ContentType do
  @moduledoc """
  Formats and parses a message body based on the content type given.

  Custom content types can be specified in your configuration.

      config :conduit, Conduit.ContentType, [{"application/x-custom", MyApp.CustomContentType}]

  Note that any new content types specified in this way will require a recompile of Conduit.

      $ mix deps.clean conduit --build
      $ mix deps.get

  Any custom content types should implement the Conduit.ContentType
  behaviour. See `Conduit.ContentType.JSON` for an example.

  """
  @callback format(Conduit.Message.t(), Keyword.t()) :: Conduit.Message.t()
  @callback parse(Conduit.Message.t(), Keyword.t()) :: Conduit.Message.t()

  @default_content_types [
    {"text/plain", Conduit.ContentType.Text},
    {"application/json", Conduit.ContentType.JSON},
    {"application/x-erlang-binary", Conduit.ContentType.ErlangBinary}
  ]

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.ContentType
      import Conduit.Message
    end
  end

  @doc """
  Formats the message body with the specified content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> Conduit.ContentType.format("application/json", [])
      iex> message.body
      "{}"

  """
  @spec format(Conduit.Message.t(), String.t(), Keyword.t()) :: Conduit.Message.t()
  def format(message, type, opts) do
    content_type(type).format(message, opts)
  end

  @doc """
  Parses the message body with the specified content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.ContentType.parse("application/json", [])
      iex> message.body
      %{}

  """
  @spec parse(Conduit.Message.t(), String.t(), Keyword.t()) :: Conduit.Message.t()
  def parse(message, type, opts) do
    content_type(type).parse(message, opts)
  end

  @spec content_type(String.t()) :: module
  config_content_types = Application.get_env(:conduit, Conduit.ContentType, [])

  for {type, content_type} <- config_content_types ++ @default_content_types do
    defp content_type(unquote(type)), do: unquote(content_type)
  end

  defp content_type(content_type) do
    raise Conduit.UnknownContentTypeError, "Unknown content type #{inspect(content_type)}"
  end
end
