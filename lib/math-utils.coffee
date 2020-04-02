{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

module.exports = MathUtils =

  integrator:  null
  parser:      null
  parserLatex: null

  evaluateExpression: (rawExpression) ->
    if rawExpression.startsWith 'integrate('
      return @integrate rawExpression

    @setParser()
    @setLatexParser()
    
    try
      result = allowUnsafeEval => allowUnsafeNewFunction =>
        @parserLatex.fromLatex(rawExpression).evaluate()

      if typeof result is 'function'
        result = 'saved'

    catch error
      try
        result = allowUnsafeEval => allowUnsafeNewFunction =>
          @parser.eval rawExpression

        if typeof result is 'function'
          result = 'saved'

      catch error_inner
        result = error+""
        if(error+"" != error_inner+"")
          result += " | "+error_inner

    result

  integrate: (rawExpression) ->
    splittedExpression = rawExpression.split('integrate(')[1]
    functionName = splittedExpression.split(',')[0].trim()
    startPoint   = parseInt splittedExpression.split(',')[1].trim()
    endPoint     = parseInt splittedExpression.split(',')[2].trim()
    pace         = parseInt splittedExpression.split(',')[3].split(')')[0].trim()

    @setParser()

    concreteFunction = allowUnsafeEval => allowUnsafeNewFunction =>
      @parser.get functionName

    @integrator ?= require 'integrate-adaptive-simpson'
    @integrator concreteFunction, startPoint, endPoint, pace

  setParser: ->
    @parser ?= allowUnsafeEval ->
      allowUnsafeNewFunction -> require('mathjs').parser()
      
  setLatexParser: ->
    @parserLatex ?= allowUnsafeEval ->
      allowUnsafeNewFunction -> require('math-expressions')
