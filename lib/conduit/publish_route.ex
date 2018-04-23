defmodule Conduit.PublishRoute do
  defstruct [:name, :opts, :pipelines]

  def new(name, opts) do
    %__MODULE__{
      name: name,
      opts: opts
    }
  end

  def put_pipelines(%__MODULE__{} = route, pipelines) do
    %{route | pipelines: pipelines}
  end
end
