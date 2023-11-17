defmodule Brew.Validation.Assert do
  use Vex.Validator

  def validate(data, options) do
    message = case Keyword.fetch!(options, :message) do
      {:ok, msg} -> msg
      true -> "no message given"
    end

    raise "expected nil (#{message}), got: #{inspect(data)}"
  end
end
