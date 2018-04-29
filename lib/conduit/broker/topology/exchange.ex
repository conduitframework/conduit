defmodule Conduit.Broker.Topology.Exchange do
  defstruct name: nil, opts: []

  def new(name, opts) when is_function(name), do: new(name.(), opts)
  def new(name, opts) when is_function(opts), do: new(name, opts.())

  def new(name, opts) do
    %__MODULE__{
      name: name,
      opts: opts
    }
  end

  def to_tuple(%__MODULE__{} = data) do
    {:exchange, data.name, data.opts}
  end
end
