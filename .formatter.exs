[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"],
  export: [
    locals_without_parens: [
      # Plug functions
      plug: 1,
      plug: 2,
      # Router macros
      get: 2,
      post: 2,
      put: 2,
      delete: 2,
      patch: 2,
      scope: 2,
      scope: 3,
      pipe_through: 1,
      # Phoenix Channel macros
      channel: 2,
      channel: 3
    ]
  ]
]
