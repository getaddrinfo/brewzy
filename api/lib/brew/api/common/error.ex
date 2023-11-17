defmodule Brew.Api.Common.Error do
  use Brew.Api.Models.Base, fields: ~w(message code)a

  def to_json(%__MODULE__{ } = error) do
    Jason.encode!(%{ error: error })
  end
end
