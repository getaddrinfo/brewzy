defmodule Brew.Cache.Formulae do
  use GenServer

  @parent :brew_cache_formulae

  defmodule State do
    defstruct [:table]

    @type t :: %__MODULE__{
      table: :ets.table()
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def update(new) do
    GenServer.call(__MODULE__, {:set, new})
  end

  def by_name(name) do
    GenServer.call(__MODULE__, {:lookup_name, name})
  end

  def by_hash(hash) do
    GenServer.call(__MODULE__, {:lookup_hash, hash})
  end

  @spec init(any()) :: {:ok, State.t()}
  @impl true
  def init(_) do
    tab = :ets.new(
      @parent,
      [:ordered_set, :protected, :named_table]
    )

    {:ok, %State{table: tab}}
  end

  @impl true
  def handle_call({:set, data}, _from, state) do
    mapped = Enum.map(data, fn it -> {
      Map.get(it, "name"),
      Map.get(it, "hash"),
      it
    } end)

    :ets.insert(@parent, mapped)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_table_reference, _from, state) do
    {:reply, {:ok, @parent}, state}
  end

  @impl true
  def handle_call({:lookup_name, name}, _from, state) do
    res = case :ets.lookup(@parent, name) do
      [{^name, hash, data}] ->
        data = data
        |> Map.put("hash", hash)
        |> Map.put("name", name)

        {:ok, data}
      [] -> {:error, :miss}
    end

    {:reply, res, state}
  end


  @impl true
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@parent)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:lookup_hash, hash}, _from, state) do
    res = case :ets.match_object(@parent, {:"$0", hash, :"$2"}) do
      [{^hash, name, data}] ->
        data = data
        |> Map.put("hash", hash)
        |> Map.put("name", name)

        {:ok, data}
      [] -> {:error, :miss}
    end

    {:reply, res, state}
  end

  defmodule ETS do
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
    - dependencies
    - test_dependencies
    - recommended_dependencies
    - optional_dependencies
    - macos_usages
    - requirements
    - conflicts
    - link_overwrites (?)
    - services
    - variations
    - head_dependencies

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

    def into(source), do: [
      base(source),
    ]

    defp base(document) do
      {get, _} = getter(document)

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
        {get.("stable"), get.("head"), get.("bottle")}, # the git hashes (I think) of the current versions, plus if it is a botle
        get.("revision"), # the current revision
        {get.("keg_only"), get.("keg_only_reason")}, # if the formula is keg only (is_keg_only)
        get.("options"), # options for the keg
        get.("pinned"), # if it's pinned (is_pinned)
        get.("outdated"), # if it's outdated (is_outdated)
        {get.("deprecated"), get.("deprecation_date"), get.("deprecation_reason")}, # {is_deprecated, date, reason}
        {get.("disabled"), get.("disable_date"), get.("disable_reason")}, # {is_disabled, date, reason}
        get.("post_install_defined"), # has_post_install_defined
        get.("tap_git_head"), # the head of the git repo for the tap
        {get.("ruby_source_checksum"), get.("ruby_source_path")}, # the checksum and path of the definition of this
      }}
    end

    defp aliases(source) do
      {get, _} = getter(source)
      name = get.("name")

      # TODO: make sure this is ideal
      {:brew_cache_formulae_aliases, Enum.map(get.("aliases"), fn (it) -> {
        it,
        name
      } end)}
    end

    defp bottles(source) do

    end

    defp getter(source) do
      {
        fn (key) -> Map.get(key, source, nil) end,
        fn (key, default) -> Map.get(key, source, default) end
      }
    end
  end
end
