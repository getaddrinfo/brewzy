defmodule Brew.Api.Models.Meta do
  use Brew.Api.Models.Base, fields: ~w(schedule sources)a

  @type t :: %__MODULE__{
    schedule: %{String.t() => Schedule},
    sources: %{String.t() => list(any())}
  }

  defmodule Source do
    defmodule Git do
      alias Brew.Job.Git
      use Brew.Api.Models.Base, fields: ~w(url branch)a

      def from(%Git.Source{branch: branch, url: url}) do
        %__MODULE__{
          url: url,
          branch: branch |> Atom.to_string
        }
      end
    end
  end

  defmodule Schedule do
    use Brew.Api.Models.Base, fields: ~w(last_executed_at period)a

    @type t :: %__MODULE__{
      last_executed_at: String.t(),
      period: non_neg_integer()
    }
  end
end
