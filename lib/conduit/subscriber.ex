defmodule Conduit.Subscriber do
  @moduledoc """
  Provides functions and macros for handling incoming messages
  """

  @callback process(Conduit.Message.t(), Conduit.Plug.opts()) :: Conduit.Message.t()

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Conduit.Plug.Builder
      @behaviour Conduit.Subscriber

      def call(message, next, opts) do
        process(message, opts)
      end

      def process(message, _opts) do
        message
      end

      defoverridable process: 2
    end
  end
end
