defmodule Conduit.Adapter do
  # @type queue_declaration :: {String.t, Keyword.t}
  # @type exchange_declaration :: {String.t, Keyword.t}
  # @type subscriber :: {String.t, [Module.t], Module.t, Keyword.t}
  # @type publisher :: {atom, [Module.t], Keyword.t}

  # @callback configure([exchange_declaration], [queue_declaration]) :: :ok | {:error, term}
  # @callback subscribe([subscribe_declaration]) :: Conduit.Message.t
end
