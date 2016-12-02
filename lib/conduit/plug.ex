defmodule Conduit.Plug do
  @moduledoc """
  Defines the plug behavior
  """
  @type opts :: tuple | atom | integer | float | [opts]
  @type next :: (Conduit.Message.t -> Conduit.Message.t)

  @callback init(opts) :: opts
  @callback call(Conduit.Message.t, next, opts) :: Conduit.Message.t
  @callback run(Conduit.Message.t, opts) :: Conduit.Message.t
  @callback __build__(next, opts) :: next
end
