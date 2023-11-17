defmodule Brew.Validation.IntBool do
  use Vex.Validator

  def validate(data, _options) do
    case data do
      1 -> :ok
      0 -> :ok
      _ -> {:error, "not a valid integer representation of a boolean"}
    end
  end
end
