defmodule Brew.Job.Git.Source do
  use Brew.Api.Models.Base, fields: ~w(url name branch)a

  @type t :: %__MODULE__{
    url: String.t(),
    name: String.t(),
    branch: String.t() | nil
  }

  def from(map) do
    %__MODULE__{
      url: map["url"],
      name: map["name"],
      branch: map["branch"]
    }
  end

  def for(url, name, branch \\ :master) do
    %__MODULE__{
      url: url,
      name: name,
      branch: branch
    }
  end
end
