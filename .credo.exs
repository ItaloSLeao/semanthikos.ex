%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Consistency.Tabs},
        {Credo.Check.Consistency.SpaceAfterCommas},
        {Credo.Check.Consistency.MultiAliasImportRequireUse},
        {Credo.Check.Consistency.ParameterPatternMatching},
        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs},
        {Credo.Check.Readability.ParenthesesInCondition},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.PreferImplicitTry},
        {Credo.Check.Readability.RedundantBlankLines},
        {Credo.Check.Readability.Semicolons},
        {Credo.Check.Readability.SpaceAfterCommas},
        {Credo.Check.Readability.StringSigils},
        {Credo.Check.Readability.TrailingBlankLine},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.VariableNames},
        {Credo.Check.Refactor.DoubleBooleanNegation},
        {Credo.Check.Refactor.CondStatements},
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 15},
        {Credo.Check.Refactor.FunctionArity, max_arity: 7},
        {Credo.Check.Refactor.MatchInCondition},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.PipeIntoAnonymousFunctions},
        {Credo.Check.Refactor.FilterReject},
        {Credo.Check.Refactor.MapInto},
        {Credo.Check.Warning.BoolOperationOnSameValues},
        {Credo.Check.Warning.ExpensiveEmptyEnumCheck},
        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.LazyLogging},
        {Credo.Check.Warning.MapGetUnsafePass}
      ]
    }
  ]
}
