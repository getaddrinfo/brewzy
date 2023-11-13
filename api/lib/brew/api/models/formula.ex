defmodule Brew.Api.Models.Formula do
  alias Brew.Api.Models.Base

  defmodule Get do
    use Base, fields: ~w(name full_name description home_page license has_post_install is_outdated is_core dependencies conflicts deprecation keg_only)a

    @type t() :: %__MODULE__{
      name: String.t(),
      full_name: String.t() | nil,
      description: String.t() | nil,
      home_page: String.t() | nil,
      license: String.t() | nil,

      dependencies: %{String.t() => list(String.t())},
      conflicts: %{String.t() => String.t()},

      has_post_install: boolean(),
      is_outdated: boolean(),
      is_core: boolean(),
      deprecation: Deprecation.t() | nil,
      keg_only: KegOnly.t() | nil
    }

    defmodule Dependencies do
      use Base, fields: ~w(base build optional recommended test)a

      @type deplist() :: list(String.t())
      @type t() :: %__MODULE__{
        base: deplist(),
        build: deplist(),
        optional: deplist(),
        recommended: deplist(),
        test: deplist()
      }

      def from(raw) do
        get = fn (name) -> Map.get(raw, name, []) end

        %__MODULE__{
          base: get.("dependencies"),
          test: get.("test_dependencies"),
          build: get.("build_dependencies"),
          recommended: get.("recommended_dependencies"),
          optional: get.("optional_dependencies")
        }
      end
    end

    defmodule Deprecation do
      use Base, fields: ~w(on reason)a

      def from(raw) do
        get = fn (name) -> Map.get(raw, name, nil) end
        case get.("deprecated") do
          true -> make(get)
          false -> nil
        end
      end


      defp make(get) do
        %__MODULE__{
          on: get.("deprecation_date"),
          reason: get.("deprecation_reason")
        }
      end
    end

    defmodule KegOnly do
      use Base, fields: ~w(reason explanation)a

      @type t() :: %__MODULE__{
        reason: String.t()
      }

      def from(raw) do
        get = fn (name) -> Map.get(raw, name) end

        case get.("keg_only") do
          true -> make(get)
          false -> nil
        end
      end

      defp make(get) do
        data = get.("keg_only_reason")

        explanation = case data["explanation"] do
          "" -> nil
          true -> data["explanation"]
        end

        # seems they just have raw ruby atoms in there?
        reason = String.trim_leading(data["reason"], ":")

        %__MODULE__{
          reason: reason,
          explanation: explanation
        }
      end
    end

    @spec from(any()) :: Api.Brew.Models.Formula.Get.t()
    def from(raw) do
      get = getter(raw)

      %Get{
        name: get.("name"),
        full_name: get.("full_name"),
        description: get.("desc"),
        license: get.("license"),
        home_page: get.("homepage"),

        conflicts: conflicts(raw),
        dependencies: Get.Dependencies.from(raw),

        has_post_install: get.("post_install_defined"),
        is_outdated: get.("outdated"),
        is_core: is_core?(raw),

        deprecation: Get.Deprecation.from(raw),
        keg_only: Get.KegOnly.from(raw)
      }
    end

    defp conflicts(raw) do
      IO.inspect(%{
        "cf" => raw["conflicts_with"],
        "reasons" => raw["conflicts_with_reasons"]
      })

      Enum.zip(
        Map.get(raw, "conflicts_with", []),
        Map.get(raw, "conflicts_with_reasons", [])
      )
      |> Enum.reduce(%{}, fn ({name, reason}, acc) -> Map.put(acc, name, reason) end)
      |> IO.inspect()
    end

    defp getter(source) do
      fn (name) -> Map.get(source, name, nil) end
    end

    defp is_core?(raw) do
      Map.get(raw, "tap", nil) == "homebrew/core"
    end
  end
end
