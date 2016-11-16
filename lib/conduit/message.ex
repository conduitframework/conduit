defmodule Conduit.Message do
  @moduledoc """
  The Conduit message.

  This module defines a `Conduit.Message` struct and the main functions
  for working with Conduit messages.

  Note this struct is used for sending and receiving messages from a
  message queue.

  ## Public fields

  These fields are for you to use in your application. The values in
  `meta`, `headers`, and `status` may have special meaning based on
  the adapter you use. See your adapters documention to understand
  how to use them correctly.

    * `meta` - Information applicable to every message stored as a map.
    * `headers` - Information applicable to a specific message stored as a keyword list.
    * `body` - The contents of the message.
    * `status` - The operation to perform on the message. This only applies to messages
      that are being received.

  ## Private fields

  These fields are reserved for library/framework usage.

    * `private` - shared library data as a map
  """

  @type source :: binary
  @type destination :: binary
  @type meta :: %{atom => any}
  @type headers :: Keyword.t
  @type body :: any
  @type status :: :ack | :nack
  @type assigns :: %{atom => any}
  @type private :: %{atom => any}

  @type t :: %__MODULE__{
    source: source,
    destination: destination,
    meta: meta,
    headers: headers,
    body: body,
    status: status,
    assigns: assigns,
    private: private
  }
  defstruct source: nil,
            destination: nil,
            meta: %{},
            headers: [],
            body: nil,
            status: :ack,
            assigns: %{},
            private: %{}

  alias Conduit.Message

  @doc """
  Assigns the source of the message.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_source(message, "my.queue")
      iex> message.source
      "my.queue"

  """
  @spec put_source(Conduit.Message.t, source) :: Conduit.Message.t
  def put_source(%Message{} = message, source) do
    %{message | source: source}
  end

  @doc """
  Assigns the destination of the message.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_destination(message, "my.queue")
      iex> message.destination
      "my.queue"

  """
  @spec put_destination(Conduit.Message.t, destination) :: Conduit.Message.t
  def put_destination(%Message{} = message, destination) do
    %{message | destination: destination}
  end

  @doc """
  Assigns a meta property to the message.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_meta(message, :content_type, "application/json")
      iex> message.meta.content_type
      "application/json"

  """
  @spec put_meta(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def put_meta(%Message{meta: meta} = message, key, value) when is_atom(key) do
    %{message | meta: Map.put(meta, key, value)}
  end

  @doc """
  Assigns a meta property to the message if not already set.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_new_meta(message, :content_type, "application/json")
      iex> message = Conduit.Message.put_new_meta(message, :content_type, "application/xml")
      iex> message.meta.content_type
      "application/json"

  """
  @spec put_new_meta(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def put_new_meta(%Message{meta: meta} = message, key, value) when is_atom(key) do
    %{message | meta: Map.put_new(meta, key, value)}
  end

  @doc """
  Returns a header from the message specified by `key`.

  ## Examples

      iex> message = %Conduit.Message{headers: [retries: 1]}
      iex> Conduit.Message.get_header(message, :retries)
      1

  """
  @spec get_header(Conduit.Message.t, atom | binary) :: any
  def get_header(%Message{headers: headers}, key) when is_atom(key) or is_binary(key) do
    Enum.find_value(headers, nil, fn
      {^key, value} -> value
      _ -> nil
    end)
  end

  @doc """
  Assigns a header for the message specified by `key`.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_header(message, :retries, 1)
      iex> Conduit.Message.get_header(message, :retries)
      1
  """
  @spec put_header(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def put_header(%Message{headers: headers} = message, key, value) when is_atom(key) do
    %{message | headers: Keyword.put(headers, key, value)}
  end

  @doc """
  Assigns the content of the message.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_body(message, "hi")
      iex> message.body
      "hi"

  """
  @spec put_body(Conduit.Message.t, body) :: Conduit.Message.t
  def put_body(%Message{} = message, body) do
    %{message | body: body}
  end

  @doc """
  Assigs the status of the message as acknowledged. This will be used
  to signal to the message queue that processing the message was successful
  and can be discarded.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.ack(message)
      iex> message.status
      :ack

  """
  @spec ack(Conduit.Message.t) :: Conduit.Message.t
  def ack(message) do
    %{message | status: :ack}
  end

  @doc """
  Assigs the status of the message to a negative acknowledged. This will be used
  to signal to the message queue that processing the message was not successful.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.nack(message)
      iex> message.status
      :nack

  """
  @spec nack(Conduit.Message.t) :: Conduit.Message.t
  def nack(message) do
    %{message | status: :nack}
  end

  @doc """
  Assigns a named value to the message.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.assign(message, :user_id, 1)
      iex> message.assigns.user_id
      1

  """
  @spec assign(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def assign(%Message{assigns: assigns} = message, key, value) when is_atom(key) do
    %{message | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Assigns a named value to the message. This is intended for libraries and framework use.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Message.put_private(message, :message_id, 1)
      iex> message.private.message_id
      1

  """
  @spec put_private(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def put_private(%Message{private: private} = message, key, value) when is_atom(key) do
    %{message | private: Map.put(private, key, value)}
  end
end
