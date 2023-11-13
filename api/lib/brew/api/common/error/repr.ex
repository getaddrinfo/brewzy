defmodule Brew.Api.Common.Error.Repr do
  # preserves ordering
  @derive {Jason.Encoder, only: ~w(code message)a}
  defstruct [:code, :message]

  def to_json(it) do
    Jason.encode!(%{error: it })
  end
end
