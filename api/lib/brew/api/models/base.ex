defmodule Brew.Api.Models.Base do
  @callback from(raw :: any()) :: any()

  defmacro __using__(opts) do
    fields = Keyword.fetch!(opts, :fields)

    # the following does produce warnings when compiling models,
    #
    # TODO: maybe work out if we can ignore them? we specify this because
    # it maintains ordering of keys in the encoded response object (instead
    # of alphabetical)
    quote do
      @behaviour Brew.Api.Models.Base
      @derive {Jason.Encoder, only: unquote(fields)}

      defstruct unquote(fields)
    end
  end
end
