defmodule Brew.Api.Models.Base do
  @callback from(raw :: any()) :: any()

  defmacro __using__(opts) do
    fields = Keyword.fetch!(opts, :fields)

    # the following does produce warnings when compiling models,
    # but we use it because it maintains order in fields
    quote do
      @derive {Jason.Encoder, only: unquote(fields)}
      defstruct unquote(fields)
    end
  end
end
