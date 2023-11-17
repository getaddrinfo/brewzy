defmodule Brew.Validation.Bool do
  use Vex.Validator

  def validate(value, _options) do
    case value do
      true -> :ok
      false -> :ok
      _ -> {:error, "not a valid strict boolean"}
    end
  end
end
