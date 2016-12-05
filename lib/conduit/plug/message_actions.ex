defmodule Conduit.Plug.MessageActions do
  @moduledoc """
  Provides `Conduit.Message` methods as plugs.
  """

  @doc """
  Proxies to `Conduit.Message.put_header/3` and calls the next plug.

  Options should be a `Map`.

  ## Examples

      import Conduit.Plug.MessageActions
      plug :put_header, %{"transfer_encoding" => "gzip"}

      iex> import Conduit.Plug.MessageActions
      iex> message = put_header(%Conduit.Message{}, &(&1), %{"transfer_encoding" => "gzip"})
      iex> Conduit.Message.get_header(message, "transfer_encoding")
      "gzip"

  """
  @spec put_header(Conduit.Message.t, Conduit.Plug.next, Conduit.Message.headers) :: Conduit.Message.t
  def put_header(message, next, opts) when is_function(next) do
    Enum.reduce(opts, message, fn {key, value}, mess ->
      Conduit.Message.put_header(mess, key, value)
    end)
    |> next.()
  end

  @doc """
  Proxies to `Conduit.Message.assign/3` and calls the next plug.

  Options should be a `Keyword` list.

  ## Examples

      import Conduit.Plug.MessageActions
      plug :assign, one: 1, two: 2

      iex> import Conduit.Plug.MessageActions
      iex> message = assign(%Conduit.Message{}, &(&1), one: 1)
      iex> Conduit.Message.assigns(message, :one)
      1

  """
  @spec assign(Conduit.Message.t, Conduit.Plug.next, Keyword.t) :: Conduit.Message.t
  def assign(message, next, opts) when is_function(next) do
    Enum.reduce(opts, message, fn {key, value}, mess ->
      Conduit.Message.assign(mess, key, value)
    end)
    |> next.()
  end

  @doc """
  Proxies to `Conduit.Message.put_private/3` and calls the next plug.

  Options should be a `Keyword` list.

  ## Examples

      import Conduit.Plug.MessageActions
      plug :put_private, one: 1, two: 2

      iex> import Conduit.Plug.MessageActions
      iex> message = put_private(%Conduit.Message{}, &(&1), one: 1)
      iex> Conduit.Message.get_private(message, :one)
      1

  """
  @spec put_private(Conduit.Message.t, Conduit.Plug.next, Keyword.t) :: Conduit.Message.t
  def put_private(message, next, opts) when is_function(next) do
    Enum.reduce(opts, message, fn {key, value}, mess ->
      Conduit.Message.put_private(mess, key, value)
    end)
    |> next.()
  end

  @before_compile Conduit.Plug.MessageActions.Generator

  defmodule Generator do
    @moduledoc false

    @actions_with_options [
      put_source: "my.queue",
      put_destination: "my.queue",
      put_user_id: 1,
      put_correlation_id: 1,
      put_new_correlation_id: 1,
      put_message_id: 1,
      put_new_message_id: 1,
      put_content_type: "application/json",
      put_content_encoding: "gzip",
      put_created_by: "my_app",
      put_body: "REDACTED"
    ]

    @status_actions [:ack, :nack]

    @doc false
    defmacro __before_compile__(_env) do
      actions_with_options = for {action, value} <- @actions_with_options do
        field =
          action
          |> to_string
          |> String.replace_leading("put_", "")
          |> String.replace_leading("new_", "")

        quote do
          @doc """
          Proxies to `Conduit.Message.#{unquote(action)}/2` and calls the next plug.

          See `Conduit.Message/#{unquote(action)}/2` for what values should be passed.

          ## Examples

              import Conduit.Plug.MessageActions
              plug :#{unquote(action)}, #{inspect(unquote(value))}

              iex> import Conduit.Plug.MessageActions
              iex> message = #{unquote(action)}(%Conduit.Message{}, &(&1), #{inspect(unquote(value))})
              iex> message.#{unquote(field)}
              #{inspect(unquote(value))}

          """
          @spec unquote(action)(Conduit.Message.t, Conduit.Plug.next, Conduit.Plug.opts) :: Conduit.Message.t
          def unquote(action)(message, next, opts) do
            apply(Conduit.Message, unquote(action), [message, opts])
            |> next.()
          end
        end
      end

      status_actions = for action <- @status_actions do
        quote do
          @doc """
          Proxies to `Conduit.Message.#{unquote(action)}/1` and calls the next plug.

          Options are ignored.

          ## Examples

              import Conduit.Plug.MessageActions
              plug :#{unquote(action)}

              iex> import Conduit.Plug.MessageActions
              iex> message = #{unquote(action)}(%Conduit.Message{}, &(&1), [])
              iex> message.status
              #{inspect(unquote(action))}

          """
          @spec unquote(action)(Conduit.Message.t, Conduit.Plug.next, Conduit.Plug.opts) :: Conduit.Message.t
          def unquote(action)(message, next, _opts) do
            apply(Conduit.Message, unquote(action), [message])
            |> next.()
          end
        end
      end

      actions_with_options ++ status_actions
    end
  end
end
