defmodule Brew.Cache.Formulae.ETS do
  @moduledoc """
  This module handles parsing into many tuples that are inserted into ETS. Whilst it would be easier
  to simply store the raw document in ets, and operate on that - we can't easily match values from it.

  The ETS (Brew.Cache.Casks.ETS) splits the raw data into separate parts that can be inserted into different ETS tables.
  Each part of data will include a reference back up to the parent document, which can then be used to build the whole document
  and return it to the caller.

  The following ETS tables are used (and are all prefixed with brew_cache_formulae):
  - aliases
  - urls

  - bottles
  - bottle_files

  - dependencies
  - test_dependencies
  - recommended_dependencies
  - optional_dependencies
  - head_dependencies
  - conflicts
  - requirements
  - macos_usages

  - services
  - variations

  Data is produced in the following format(s):
  {
    table :: :ets.table(),
    {
      pkey :: any(),
      ...rest:: any()
    }
  }

  or

  {
    table :: :ets.table(),
    [
      {
        pkey :: any(),
        ...rest :: any()
      },
      ...
    ]
  }
  """
  @parent :brew_cache_formulae
  @tables [
    :aliases,
    :urls,
    :bottles,
    :bottle_files,
    :dependencies,
    :test_dependencies,
    :recommended_dependencies,
    :optional_dependencies,
    :head_dependencies,
    :conflicts,
    :requirements,
    :macos_usages,
    :variations,
  ] |> Enum.map(fn it ->
    "#{Atom.to_string(@parent)}_#{Atom.to_string(it)}"
    |> String.to_atom()
  end)

  @all @tables ++ [@parent]

  @spec into(map()) :: list(any())
  def into(source), do: [
    base(source),
    aliases(source),
    bottles(source),
    bottle_files(source)
  ]

  defp base(document) do
    {get, _} = getter(document)

    # name = get.("name")

    versions = case get.("versions") do
      nil -> nil
      data -> {
        Map.get(data, "stable"),
        Map.get(data, "head"),
        Map.get(data, "bottle")
      }
    end

    deprecated = case get.("deprecated") do
      false -> nil
      true -> {
        get.("deprecation_date"),
        get.("deprecation_reason")
      }
    end

    disabled = case get.("disabled") do
      false -> nil
      true -> {
        get.("disable_date"),
        get.("disable_reason")
      }
    end

    keg_only = case get.("keg_only") do
      false -> nil
      true -> get.("keg_only_reason")
    end

    bottles = case get.("bottle") do
      nil -> nil
      data -> Map.keys(data)
    end

    bottle_files = get.("bottle")
    |> Enum.map(
      fn ({ version, data }) ->
        {
          version,
          data
          |> Map.get("files", %{})
          |> Map.keys()
        }
      end
    )

    conflicts = get.("conflicts_with")
    requirements = get.("requirements")

    {:brew_cache_formulae, {
      get.("name"), # the name of the package (primary key)
      get.("full_name"), # the full name of the package (if applicable)
      get.("tap"), # the tap that this package belongs to (we keep other taps as well)
      get.("oldname"), # the previous name of the package
      get.("oldnames"), # the previous names of the package (TODO: investigate)
      get.("aliases"), # aliases for the package (TODO: reverse lookup?)
      get.("versioned_formulae"), # TODO: split out?
      get.("desc"), # description of the package
      get.("license"), # license type of the package
      get.("homepage"), # the homepage of the package
      versions, # the git hashes (I think) of the current versions, plus if it is a botle
      get.("revision"), # the current revision
      keg_only, # String.t() | nil
      get.("options"), # options for the keg
      get.("pinned"), # if it's pinned (is_pinned)
      get.("outdated"), # if it's outdated (is_outdated)
      deprecated, # {date, reason} | nil
      disabled, # {is_disabled, date, reason}
      get.("post_install_defined"), # has_post_install_defined
      get.("tap_git_head"), # the head of the git repo for the tap
      {get.("ruby_source_checksum")["sha256"], get.("ruby_source_path")}, # the checksum and path of the definition of this,
      get.("link_overwrite"), # link overwrites
      get.("service"), # TODO: map into actual structure!!!!
      # data that points to other tables in ets
      # order matters, as that is how we know what
      # table to get from (saves some space)
      {
        {:brew_cache_formulae_bottles, bottles},
        {:brew_cache_formulae_bottle_files, bottle_files},
        {:brew_cache_conflicts, conflicts},
        {:brew_cache_requirements, requirements},
        {:brew_cache_}
      }
    }}
  end

  defp aliases(source) do
    {get, _} = getter(source)
    name = get.("name")

    # TODO: make sure this is ideal (i.e., no clashes)
    {:brew_cache_formulae_aliases, Enum.map(get.("aliases"), fn (it) -> {
      it,
      name
    } end)}
  end


  defp bottles(source) do
    # key = {name, release, target}
    # value = {cellar, url, sha256}

    {get, _} = getter(source)
    data = get.("bottle")
    name = get.("name")

    {:brew_cache_formulae_bottles, Enum.map(data, fn ({ version, meta }) -> {
      {name, version},
      Map.get(meta, "rebuild", 0) == 1,
      Map.get(meta, "root_url"),
      Map.get(meta, "files", %{}) |> Map.keys()
    } end)}
  end

  defp bottle_files(source) do
    {get, _} = getter(source)
    name = get.("name")

    reduced = Enum.flat_map(
      get.("bottle"),
      fn ({ variant, data }) -> Map.get(data, "files", []) |> Enum.map(
        fn ({ target, target_data }) -> {
          {name, variant, target},
          target_data["cellar"],
          target_data["url"],
          target_data["sha256"]
        } end
      ) end
    )

    {
      :brew_cache_formulae_bottle_files,
      reduced
    }
  end


  @spec getter(any()) :: any()
  defp getter(source) do
    {
      fn (key) -> Map.get(source, key, nil) end,
      fn (key, default) -> Map.get(source, key, default) end
    }
  end

  def create do
    @all
    |> Enum.each(&create/1)
  end

  defp create(name) when is_atom(name) do
    :ets.new(name, [:set, :protected, :named_table])
  end

  def clear do
    @all
    |> Enum.each(&clear/1)
  end

  defp clear(table) do
    :ets.delete_all_objects(table)
  end

  def tables do
    @all
  end

  # def table(:formulae), do: :brew_cache_formulae
  # def table(:aliases), do: :brew_cache_formulae_aliases
  # def table(:urls), do: :brew_cache_formulae_urls
  # def table(:bottles), do: :brew_cache_formulae_bottles
  # def table(:bottle_files), do: :brew_cache_formulae_bottle_files
  # def table(:dependencies), do: :brew_cache_formulae_dependencies
  # def table(:test_dependencies), do: :brew_cache_formulae_test_dependencies
  # def table(:recommended_dependencies), do: :brew_cache_formulae_recommended_dependencies
  # def table(:optional_dependencies), do: :brew_cache_formulae_optional_dependencies
  # def table(:head_dependencies), do: :brew_cache_formulae_head_dependencies
  # def table(:conflicts), do: :brew_cache_formulae_conflicts
  # def table(:requirements), do: :brew_cache_formulae_requirements
  # def table(:macos_usages), do: :brew_cache_formulae_macos_usages
  # def table(:link_overwries), do: :brew_cache_formulae_link_overwrites
  # def table(:services), do: :brew_cache_formulae_services
  # def table(:variations), do: :brew_cache_formulae_variations
end
