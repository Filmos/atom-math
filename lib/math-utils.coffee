{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

module.exports = MathUtils =

  integrator:  null
  parser:      null
  parserLatex: null

  evaluateExpression: (rawExpression) ->
    if rawExpression.startsWith 'integrate('
      return @integrate rawExpression
      
    prefix = ""
    suffix = ""
      
    if (testForDollars = /^(\$+)([^$]+)(\$*)$/.exec(rawExpression)) || (testForDollars = /^(\$*)([^$]+)(\$+)$/.exec(rawExpression))
      prefix = testForDollars[1]
      rawExpression = testForDollars[2]
      suffix = testForDollars[3]

    rawExpression = rawExpression.replace(/\\binom{([^{}]+)}{([^{}]+)}/g, "{\\frac{($1)!}{($2)!*(($1)-($2))!}}")
    rawExpression = rawExpression.replace(/{([^{}]+)}\\choose{([^{}]+)}/g, "{\\frac{($1)!}{($2)!*(($1)-($2))!}}")
    rawExpression = rawExpression.replace(/\\displaystyle/g, "")
    
    @setParser()
    @setLatexParser()
    
    try
      result = allowUnsafeEval => allowUnsafeNewFunction =>
        prefix+@parserLatex.fromLatex(rawExpression).evaluate()+suffix

    catch error
      try
        result = allowUnsafeEval => allowUnsafeNewFunction =>
          @parser.eval rawExpression

        if typeof result is 'function'
          result = 'Saved'
        else
          result = prefix+result+suffix

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
