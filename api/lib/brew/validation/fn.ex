defmodule Brew.Validation.Fns do
  def do_conflicts_match(data, context) do
    cond do
      length(data) == length(context.conflicts_with_reasons) -> :ok
      true -> {:error, "conflicts mismatch"}
    end
  end

  def do_macos_bounds_match(data, context) do
    cond do
      length(data) == length(context.uses_from_macos_bounds) -> :ok
      true -> {:error, "macos bounds mismatch"}
    end
  end
end
