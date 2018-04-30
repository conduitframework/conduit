defmodule Conduit.Plug do
  @moduledoc """
  Defines the plug behaviour.

  ## Included Plugs

    * `Conduit.Plug.CorrelationId`
    * `Conduit.Plug.CreatedAt`
    * `Conduit.Plug.CreatedBy`
    * `Conduit.Plug.DeadLetter`
    * `Conduit.Plug.Decode`
    * `Conduit.Plug.Encode`
    * `Conduit.Plug.Format`
    * `Conduit.Plug.LogIncoming`
    * `Conduit.Plug.LogOutgoing`
    * `Conduit.Plug.Parse`
    * `Conduit.Plug.Retry`

  There are also many function plugs defined in `Conduit.Plug.MessageActions`
  which delegate to functions in `Conduit.Message`.

  ## Custom Plugs

  You can define your own plugs as a module or as a function. If you
  want to define a module plug, it should implement this behaviour.
  `run/2` and `__build__/2` can be tricky to build on your own, so it is
  usually better to use `Conduit.Plug.Builder`. This will give you
  default implementations of the callbacks. You can then override
  the callbacks you would like (probably `call/3` or `init/1`). See the
  included plugs above for examples.

  If you want to define a function plug, you must define a method that
  accepts three arguments. The `message`, the `next` plug to call, and
  a set of `opts`. Once you are done transforming the message, you should
  generally call `next` with the message unless you are halting the chain.
  See `Conduit.Plug.MessageActions` for examples.
  """

  @type opts :: tuple | atom | integer | float | [opts] | map | fun | binary
  @type next :: (Conduit.Message.t() -> Conduit.Message.t())

  @type t :: {atom | module, opts}

  @callback init(opts) :: opts
  @callback call(Conduit.Message.t(), next, opts) :: Conduit.Message.t()
  @callback run(Conduit.Message.t(), opts) :: Conduit.Message.t()
  @callback __build__(next, opts) :: next
end
