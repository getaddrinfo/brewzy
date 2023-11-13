defmodule Brew.Api.Common.Error.HTTP do
  alias Brew.Api.Common.Error.Repr


  def not_found do
    %Repr{
      code: nil,
      message: "Not Found"
    }
  end
end
