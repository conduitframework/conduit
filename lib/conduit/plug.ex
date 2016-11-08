defmodule Conduit.Plug do
  @type opts :: tuple | atom | integer | float | [opts]

  @callback init(opts) :: opts
  @callback call(Conduit.Message.t, opts) :: Conduit.Message.t
end
