import Config

config :vex,
  sources: [
    [
      bool: Brew.Validation.Bool,
      intbool: Brew.Validation.IntBool,
      assert: Brew.Validation.Assert,
      length_match: Brew.Validation.LengthMatch
    ],
    Vex.Validators
  ]

import_config "#{config_env()}.exs"
