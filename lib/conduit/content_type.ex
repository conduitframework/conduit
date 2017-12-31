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
  @type body :: term

  @callback format(body, Keyword.t) :: body
  @callback parse(body, Keyword.t) :: body

  @default_content_types [
    {"text/plain", Conduit.ContentType.Text},
    {"application/json", Conduit.ContentType.JSON}
  ]

  @doc """
  Defines as implementing the `Conduit.ContentType` behavior and imports `Conduit.Message`.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.ContentType
      import Conduit.Message
    end
  end

  @doc """
  Formats the message body with the specified content type.

  ## Examples

      iex> Conduit.ContentType.format("my message", "text/plain", [])
      "my message"

  """
  @spec format(body, String.t, Keyword.t) :: body
  def format(body, type, opts) do
    content_type(type).format(body, opts)
  end

  @doc """
  Parses the message body with the specified content type.

  ## Examples

      iex> Conduit.ContentType.parse("{}", "application/json", [])
      %{}

  """
  @spec parse(body, String.t, Keyword.t) :: body
  def parse(body, type, opts) do
    content_type(type).parse(body, opts)
  end

  @spec content_type(String.t) :: module
  config_content_types = Application.get_env(:conduit, Conduit.ContentType, [])
  for {type, content_type} <- config_content_types ++ @default_content_types do
    defp content_type(unquote(type)), do: unquote(content_type)
  end

  defp content_type(content_type) do
    raise Conduit.UnknownContentTypeError, "Unknown content type #{inspect content_type}"
  end
end
