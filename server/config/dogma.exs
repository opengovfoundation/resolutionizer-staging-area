use Mix.Config
alias Dogma.Rule

config :dogma,

  # Select a set of rules as a base
  rule_set: Dogma.RuleSet.All,

  # Override an existing rule configuration
  # A rule can be disabled with `enabled: false`
  override: [
    %Rule.LineLength{ max_length: 120 }
  ]
