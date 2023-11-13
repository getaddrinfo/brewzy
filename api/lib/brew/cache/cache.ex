defmodule Brew.Cache do
  @callback update(data :: term()) :: :ok
  @callback clear() :: :ok
end
