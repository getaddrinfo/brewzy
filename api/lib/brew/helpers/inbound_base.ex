defmodule Brew.Helper.InboundBase do
  @callback from(any()) :: any()

  defmacro __using__(opts) do
    fields = Keyword.fetch!(opts, :fields)

    quote do
      @behaviour Brew.Helper.InboundBase

      use Vex.Struct

      defstruct unquote(fields)
    end
  end
end
