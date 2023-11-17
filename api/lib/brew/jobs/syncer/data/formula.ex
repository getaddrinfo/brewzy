defmodule Brew.Job.Syncer.Data.Formula do
  alias Brew.Job.Syncer.Data.Formula.HeadDependencies
  alias Brew.Job.Syncer.Data.Formula.RubySourceChecksum
  alias Brew.Helper.InboundBase, as: Base

  import Brew.Helper.Getter

  # either a string or a map of string -> string (1 key as far as I can tell)
  @type uses_from_macos() :: list(String.t() | %{String.t() => String.t()})
  @type uses_from_macos_bounds() :: list(%{String.t() => String.t()}) # "since" -> date

  use Base, fields: ~w(
    name
    full_name
    tap
    oldname
    oldnames
    aliases
    versioned_formulae
    desc
    license
    homepage
    versions
    urls
    revision
    version_scheme
    bottle
    keg_only
    keg_only_reason
    options
    build_dependencies
    dependencies
    test_dependencies
    recommended_dependencies
    optional_dependencies
    uses_from_macos
    uses_from_macos_bounds
    requirements
    conflicts_with
    conflicts_with_reasons
    link_overwrite
    caveats
    installed
    linked_keg

    pinned
    outdated

    deprecated
    deprecation_date
    deprecation_reason

    disabled
    disable_date
    disable_reason
    post_install_defined

    service

    tap_git_head
    ruby_source_path
    ruby_source_checksum

    variations
    head_dependencies
  )a

  @type t :: %__MODULE__{
    name: String.t(),
    full_name: String.t(),
    tap: String.t(),
    oldname: String.t() | nil,
    oldnames: list(String.t()),
    aliases: list(String.t()),
    versioned_formulae: list(String.t()),
    desc: String.t(),
    license: String.t() | nil,
    homepage: String.t(),

    versions: Versions.t(),
    urls: URLs.t(),

    revision: non_neg_integer(),
    version_scheme: non_neg_integer(),

    bottle: Bottles.t() | nil,
    keg_only: boolean(),
    keg_only_reason: KegOnlyReason.t() | nil, # if keg_only == true -> keg_only_reason != nil
    options: list(any()), # don't know the type here

    build_dependencies: list(String.t()),
    dependencies: list(String.t()),
    test_dependencies: list(String.t()),
    recommended_dependencies: list(String.t()), # I think
    optional_dependencies: list(String.t()), # I think

    uses_from_macos: uses_from_macos(), # TODO: this
    uses_from_macos_bounds: uses_from_macos_bounds(), # TODO: this

    requirements: list(Requirement.t()),

    conflicts_with: list(String.t()),
    conflicts_with_reasons: list(String.t()),
    link_overwrite: list(String.t()),

    caveats: String.t() | nil,

    installed: list(Installed.t()) | nil, # TODO: this
    linked_keg: String.t() | nil,
    pinned: boolean(),
    outdated: boolean(),

    deprecated: boolean(),
    deprecation_date: String.t() | nil,
    deprecation_reason: String.t() | nil,

    disabled: boolean(),
    disable_date: String.t() | nil,
    disable_reason: String.t() | nil,

    post_install_defined: boolean(),

    service: Service.t() | nil, # TODO

    tap_git_head: String.t(),
    ruby_source_path: String.t(),
    ruby_source_checksum: RubySourceChecksum.t(),

    variations: %{String.t() => HeadDependencies.t()},
    head_dependencies: HeadDependencies.t(),
  }

  validates :name, presence: true
  validates :full_name, presence: true
  validates :tap, presence: true
  validates :oldname
  # TODO: tap
  # TODO: oldname
  # TODO: oldnames
  # TODO: aliases
  # TODO: versioned_formulae
  validates :desc, presence: true
  validates :license
  validates :homepage, presence: true
  # TODO: versions
  # TODO: urls
  validates :revision, number: true
  validates :version_scheme, number: true
  # TODO: bottle
  validates :keg_only, bool: true
  validates :keg_only_reason, presence: [if: [keg_only: true]]
  validates :options, length: [is: 0] # if this changes, we need to accomodate it, so validate that it's empty
  validates :build_dependencies
  validates :dependencies
  validates :test_dependencies
  validates :recommended_dependencies
  validates :optional_dependencies

  # uses_from_macos <-> uses_from_macos_bounds
  validates :requirements
  validates :conflicts_with, by: [function: &Brew.Validation.Fns.do_conflicts_match/2]
  validates :conflicts_with_reason

  # conflicts_with <-> conflicts_with_reasons
  validates :link_overwrites
  validates :caveats
  validates :installed
  validates :linked_keg
  validates :pinned, bool: true
  validates :deprecated, bool: true
  validates :deprecation_date
  validates :deprecation_reason, presence: [if: [deprecated: true]]

  validates :disabled, bool: true
  validates :disable_date, presence: [if: [disabled: true]]
  validates :disable_reason, presence: [if: [disabled: true]]
  validates :post_install_defined, bool: true
  validates :service
  validates :tap_git_head, presence: true
  validates :ruby_source_path, presence: true
  validates :ruby_source_checksum
  validates :variations
  validates :head_dependencies

  validates :uses_from_macos, by: [function: &Brew.Validation.Fns.do_macos_bounds_match/2, allow_nil: true]
  validates :uses_from_macos_bounds

  defmodule Bottles do
    use Brew.Helper.InboundBase, fields: ~w(stable)a

    @type t :: %__MODULE__{
      stable: Bottle.t()
    }

    def from(nil), do: nil

    defmodule Bottle do
      use Base, fields: ~w(rebuild root_url files)a

      @type t :: %__MODULE__{
        rebuild: boolean(),
        root_url: String.t(),
        files: %{String.t() => BottleFile.t()}
      }

      validates :rebuild, intbool: true
      validates :root_url, presence: true

      defmodule BottleFile do
        use Brew.Helper.InboundBase, fields: ~w(cellar url sha256)a

        @type t :: %__MODULE__{
          cellar: String.t(),
          url: String.t(),
          sha256: String.t()
        }

        validates :cellar, presence: true
        validates :url, presence: true
        validates :sha256, presence: true

        def parse(raw) do
          raw
          |> Enum.reduce(%{}, fn ({ dist, raw }, acc) -> Map.put(
            acc,
            dist,
            from(raw)
          ) end)
        end

        def from(raw) do
          {get, _} = getter(raw)

          %__MODULE__{
            cellar: get.("cellar"),
            url: get.("url"),
            sha256: get.("sha256")
          }
        end
      end

      def from(raw) do
        {get, _} = getter(raw)

        %__MODULE__{
          rebuild: get.("rebuild") == 1,
          root_url: get.("root_url"),
          files: BottleFile.parse(get.("files"))
        }
      end
    end

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        stable: Bottle.from(get.("stable"))
      }
    end
  end


  defmodule Versions do
    use Base, fields: ~w(stable head bottle)a

    @type t :: %__MODULE__{
      stable: String.t(),
      head: String.t() | nil,
      bottle: boolean()
    }

    validates :stable, presence: true
    validates :head, presence: [allow_nil: true]
    validates :bottle, bool: true

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        stable: get.("stable"),
        head: get.("head"),
        bottle: get.("bottle")
      }
    end
  end

  defmodule URLs do
    use Base, fields: ~w(stable head)a

    @type t :: %__MODULE__{
      stable: Stable.t(),
      head: Head.t()
    }

    validates :stable
    validates :head

    defmodule Stable do
      use Base, fields: ~w(url tag revision using checksum)a

      @type t :: %__MODULE__{
        url: String.t(),
        tag: String.t() | nil,
        revision: String.t() | nil,
        using: String.t() | nil,
        checksum: String.t() | nil
      }

      validates :url, presence: true
      validates :tag, presence: [allow_nil: true]
      validates :revision, presence: [allow_nil: true]
      validates :using, presence: [allow_nil: true]
      validates :checksum, presence: [allow_nil: true]

      def from(raw) do
        {get, _} = getter(raw)

        %__MODULE__{
          url: get.("url"),
          tag: get.("tag"),
          revision: get.("revision"),
          using: get.("using"),
          checksum: get.("checksum")
        }
      end
    end

    defmodule Head do
      use Base, fields: ~w(url branch using)a

      @type t :: %__MODULE__{
        url: String.t(),
        branch: String.t() | nil,
        using: String.t() | nil
      }

      validates :url, presence: true
      validates :branch, presence: [allow_nil: true]
      validates :using, presence: [allow_nil: true]

      def from(nil), do: nil

      def from(raw) do
        get = fn name -> Map.get(raw, name) end

        %__MODULE__{
          url: get.("url"),
          branch: get.("branch"),
          using: get.("using")
        }
      end
    end

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        stable: Stable.from(get.("stable")),
        head: Head.from(get.("head"))
      }
    end
  end

  defmodule KegOnlyReason do
    use Base, fields: ~w(reason explanation)a

    @type t :: %__MODULE__{
      reason: String.t(),
      explanation: String.t()
    }

    validates :reason, presence: true
    validates :explanation, presence: true

    def from(nil), do: nil

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        reason: get.("reason"),
        explanation: get.("explanation")
      }
    end
  end

  defmodule Requirement do
    use Base, fields: ~w(name cask download version contexts specs)a

    @type t :: %__MODULE__{
      name: String.t(),
      cask: nil,
      download: nil,
      version: String.t() | nil,
      contexts: list(String.t()),
      specs: list(String.t())
    }

    validates :name, presence: true
    validates :cask, allow_nil: true, assert: [message: "should be nil"]
    validates :download, allow_nil: true, assert: [message: "should be nil"]
    validates :version, presence: true
    # validates :contexts
    # validates :specs

    def from(raw) when is_list(raw) do
      raw
      |> Enum.map(&from/1)
    end

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        name: get.("name"),
        cask: get.("cask"),
        download: get.("download"),
        version: get.("version"),
        contexts: get.("contexts"),
        specs: get.("specs")
      }
    end
  end

  defmodule Installed do
    use Base, fields: ~w(
      version
      used_options
      built_as_bottle
      poured_from_bottle
      time
      runtime_dependencies
      installed_as_dependency
      installed_on_request
    )a

    @type t :: %__MODULE__{
      version: String.t(),
      used_options: list(any()), # unknown
      built_as_bottle: boolean(),
      poured_from_bottle: boolean(),
      time: non_neg_integer(),
      runtime_dependencies: list(RuntimeDependency.t()),
      installed_as_dependency: boolean(),
      installed_on_request: boolean()
    }

    defmodule RuntimeDependency do
      use Base, fields: ~w(
        full_name
        version
        declared_directly
      )a

      @type t :: %__MODULE__{
        full_name: String.t(),
        version: String.t(),
        declared_directly: boolean()
      }

      def from(raw) when is_list(raw) do
        raw
        |> Enum.map(&from/1)
      end

      def from(raw) do
        {get, _} = getter(raw)

        %__MODULE__{
          full_name: get.("full_name"),
          version: get.("version"),
          declared_directly: get.("declared_directly")
        }
      end
    end

    def from(nil), do: nil

    def from(list) when is_list(list) do
      list
      |> Enum.map(&from/1)
    end

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        version: get.("version"),
        used_options: get.("used_options"),
        built_as_bottle: get.("built_as_bottle"),
        poured_from_bottle: get.("poured_from_bottle"),
        time: get.("time"),
        runtime_dependencies: RuntimeDependency.from(get.("runtime_dependencies")),
        installed_as_dependency: get.("installed_as_dependency"),
        installed_on_request: get.("installed_on_request")
      }
    end
  end

  defmodule Service do
    use Base, fields: ~w(
      run
      run_type
      working_dir
      keep_alive
      log_path
      error_log_path
      environment_variables
      interval
      require_root
      cron
      sockets
      name
      process_type
      macos_legacy_timers
      input_path
      )a

    @type t :: %__MODULE__{
      run: RunContextual.parsed() | nil,
      run_type: String.t() | nil,
      working_dir: String.t() | nil,
      keep_alive: KeepAlive.t() | nil,
      log_path: String.t() | nil,
      error_log_path: String.t() | nil,
      environment_variables: %{String.t() => String.t()} | nil,
      interval: non_neg_integer() | nil,
      require_root: boolean() | nil,
      cron: String.t() | nil,
      sockets: String.t() | nil,
      name: Name.t() | nil,
      process_type: String.t() | nil,
      macos_legacy_timers: boolean() | nil,
      input_path: String.t() | nil
    }

    validates :run, presence: [allow_nil: true]
    validates :run_type, presence: [allow_nil: true]
    validates :working_dir, presence: [allow_nil: true]
    validates :keep_alive, presence: [allow_nil: true]
    validates :log_path, presence: [allow_nil: true]
    validates :error_log_path, presence: [allow_nil: true]
    validates :environment_variables, presence: [allow_nil: true]
    validates :interval, number: [allow_nil: true]
    validates :require_root, bool: [allow_nil: true]
    validates :cron, presence: [allow_nil: true]
    validates :sockets, presence: [allow_nil: true]
    validates :name
    validates :process_type, presence: [allow_nil: true]
    validates :macos_legacy_timers, bool: [allow_nil: true]
    validates :input_path, presence: [allow_nil: true]

    defmodule RunContextual do
      use Base, fields: ~w(macos linux)a

      @type t :: %__MODULE__{
        macos: list(String.t()) | nil,
        linux: list(String.t()) | nil
      }

      @type parsed() :: t() | String.t() | list(String.t())

      validates :macos
      validates :linux

      def from(nil), do: nil

      def from(it) when is_bitstring(it) do
        it
      end

      def from(it) when is_list(it) do
        it
      end

      def from(it) when is_map(it) do
        {get, _} = getter(it)

        %__MODULE__{
          macos: from(get.("macos")),
          linux: from(get.("linux"))
        }
      end
    end

    defmodule KeepAlive do
      use Base, fields: ~w(always successful_exit crashed)a

      @type t :: %__MODULE__{
        always: boolean() | nil,
        successful_exit: boolean() | nil,
        crashed: boolean() | nil
      }

      def from(nil), do: nil

      def from(raw) do
        {get, _} = getter(raw)

        %__MODULE__{
          always: get.("always"),
          successful_exit: get.("successful_exit"),
          crashed: get.("crashed")
        }
      end
    end

    defmodule Name do
      use Base, fields: ~w(macos)a

      @type t :: %__MODULE__{
        macos: String.t()
      }

      validates :macos, presence: true

      def from(nil), do: nil
      def from(raw) do
        {get, _} = getter(raw)

        %__MODULE__{
          macos: get.("macos")
        }
      end
    end

    def from(nil), do: nil
    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        run: RunContextual.from(get.("run")),
        run_type: get.("run_type"),
        working_dir: get.("working_dir"),
        keep_alive: KeepAlive.from(get.("keep_alive")),
        log_path: get.("log_path"),
        error_log_path: get.("error_log_path"),
        environment_variables: get.("environment_variables"),
        interval: get.("interval"),
        require_root: get.("require_root"),
        cron: get.("cron"),
        sockets: get.("sockets"),
        name: Name.from(get.("name")),
        process_type: get.("process_type"),
        macos_legacy_timers: get.("macos_legacy_timers"),
        input_path: get.("input_path")
      }
    end
  end

  defmodule RubySourceChecksum do
    use Base, fields: ~w(sha256)a # for now...

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        sha256: get.("sha256")
      }
    end
  end

  defmodule HeadDependencies do
    # WARN: The shape that brew uses for `uses_from_macos` is nasty
    #
    # It is basically `list(String.t() | %{String.t() => String.t()}),
    # where they can be mixed - not nice to decode.

    alias Brew.Job.Syncer.Data.Formula.MacosUsage
    alias Brew.Job.Syncer.Data.Formula

    use Base, fields: ~w(
      build_dependencies
      dependencies
      test_dependencies
      recommended_dependencies
      optional_dependencies
      uses_from_macos
      uses_from_macos_bounds
    )a

    @type t :: %__MODULE__{
      build_dependencies: list(String.t()),
      dependencies: list(String.t()),
      test_dependencies: list(String.t()),
      recommended_dependencies: list(String.t()), # I think
      optional_dependencies: list(String.t()), # I think

      uses_from_macos: Formula.uses_from_macos(),
      uses_from_macos_bounds: Formula.uses_from_macos_bounds()
    }

    validates :build_dependencies
    validates :dependencies
    validates :test_dependencies
    validates :recommended_dependencies
    validates :optional_dependencies
    validates :uses_from_macos
    validates :uses_from_macos_bounds, by: [function: &Brew.Validation.Fns.do_macos_bounds_match/2]

    def from(nil), do: nil

    def from(raw) do
      {get, _} = getter(raw)

      %__MODULE__{
        build_dependencies: get.("build_dependencies"),
        dependencies: get.("dependencies"),
        test_dependencies: get.("test_dependencies"),
        recommended_dependencies: get.("recommended_dependencies"),
        optional_dependencies: get.("optional_dependencies"),
        uses_from_macos: MacosUsage.from(get.("uses_from_macos")),
        uses_from_macos_bounds: get.("uses_from_macos_bounds")
      }
    end
  end

  defmodule MacosUsage do
    use Base, fields: ~w(
      target
      action
    )a

    @type t :: %__MODULE__{
      target: String.t(),
      action: String.t() | nil
    }

    def from(raw) do
      parse(raw)
    end

    def parse(input) when is_list(input) do
      input
      |> Enum.map(&parse/1)
    end

    # when string
    def parse(input) when is_bitstring(input) do
      %__MODULE__{
        target: input,
        action: nil
      }
    end

    # when map with single key
    def parse(input) when is_map(input) and map_size(input) == 1 do
      case Map.keys(input) do
        [target] -> {:ok, %__MODULE__{
          target: target,
          action: Map.get(input, target)
        }}
        _ -> {:error, "invariant: only one map key"}
      end
    end

    def parse(_) do
      {:error, "unexpected input for bounds"}
    end
  end

  defmodule Variations do
    alias Brew.Job.Syncer.Data.Formula.HeadDependencies

    def from(raw) do
      raw
      |> Enum.reduce(%{}, fn ({ target, data }, acc) -> Map.put(acc, target, HeadDependencies.from(data)) end)
    end
  end

  @impl true
  def from(object) do
    get = fn name -> Map.get(object, name) end

    %__MODULE__{
      name: get.("name"),
      full_name: get.("full_name"),
      tap: get.("tap"),
      oldname: get.("oldname"), # we can just drop this when analysing - always in oldnames
      oldnames: get.("oldnames"),
      aliases: get.("aliases"),
      versioned_formulae: get.("versioned_formulae"),
      desc: get.("desc"),
      license: get.("license"),
      homepage: get.("homepage"),
      versions: Versions.from(get.("versions")),
      urls: URLs.from(get.("urls")),
      revision: get.("revision"),
      version_scheme: get.("version_scheme"),
      bottle: Bottles.from(get.("bottle")),
      keg_only: get.("keg_only"),
      keg_only_reason: KegOnlyReason.from(get.("keg_only_reason")),
      options: get.("options"),
      build_dependencies: get.("build_dependencies"),
      dependencies: get.("dependencies"),
      test_dependencies: get.("test_dependencies"),
      recommended_dependencies: get.("recommended_dependencies"),
      optional_dependencies: get.("optional_dependencies"),
      uses_from_macos: MacosUsage.from(get.("uses_from_macos")),
      uses_from_macos_bounds: get.("uses_from_macos_bounds"),
      requirements: Requirement.from(get.("requirements")),
      conflicts_with: get.("conflicts_with"),
      conflicts_with_reasons: get.("conflicts_with_reasons"),
      link_overwrite: get.("link_overwrite"),
      caveats: get.("caveats"),
      installed: Installed.from(get.("installed")),
      linked_keg: get.("linked_keg"),
      pinned: get.("pinned"),
      outdated: get.("outdated"),
      deprecated: get.("deprecated"),
      deprecation_date: get.("deprecation_date"),
      deprecation_reason: get.("deprecation_reason"),
      disabled: get.("disabled"),
      disable_date: get.("disable_date"),
      disable_reason: get.("disable_reason"),
      post_install_defined: get.("post_install_defined"),
      service: Service.from(get.("service")),
      tap_git_head: get.("tap_git_head"),
      ruby_source_path: get.("ruby_source_path"),
      ruby_source_checksum: RubySourceChecksum.from(get.("ruby_source_checksum")),
      variations: Variations.from(get.("variations")),
      head_dependencies: HeadDependencies.from(get.("head_dependencies"))
    }
  end
end
