defmodule Logger.Backends.JSON.DummyEncoder do
  def encode(object), do: {:ok, inspect(object)}
end
