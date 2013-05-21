# chuck, because, why not?

NEST_FACTOR = 2

comparators = /\|\||&&|!=|==|!==|===|<|<=|>|>=/
assigners = /\=|\+=|-=|\*=|\/=|\+\+|--/
operators = /\+|-|\*|\//

calculateExpressionComplexity = (expression, options) ->
  if expression?.negative?
    return calculateExpressionComplexity expression.negative
  if expression?.inverse?
    return calculateExpressionComplexity expression.inverse
  if expression?.parenthesized?
    return calculateExpressionComplexity expression.parenthesized
  if expression?.receiver?
    cc = calculateExpressionComplexity expression.receiver
    cc += calculateExpressionComplexity expression.index if expression.index?
    return cc
  if expression?.argv?
    cc = 0
    cc += calculateExpressionComplexity arg for arg in expression.argv
    return cc
  if expression?.callee? and expression?.initializer?
    cc = 0
    cc += calculateExpressionComplexity expr for expr in expression.initializer
    return cc
  if comparators.test expression?.operator
    return 1 + calculateExpressionComplexity expression.left +
               calculateExpressionComplexity expression.right
  if assigners.test expression?.operator
    return 1 + calculateExpressionComplexity expression.value
  if operators.test expression?.operator
    return calculateExpressionComplexity expression.left +
           calculateExpressionComplexity expression.right
  if expression?.condition?
    return 1 + calculateExpressionComplexity expression.condition +
               calculateExpressionComplexity expression.trueValue +
               calculateExpressionComplexity expression.falseValue
  0

countExpressionHalstead = (expression) ->
  if expression?.negative?
    hal = countExpressionHalstead expression.negative
    hal.operators.push '-'
    return hal
  if expression?.inverse?
    hal = countExpressionHalstead expression.inverse
    hal.operators.push '!'
    return hal
  if expression?.parenthesized?
    hal = countExpressionHalstead expression.parenthesized
    hal.operators.push '()'
    return hal
  if expression?.receiver?
    hals = [countExpressionHalstead expression.receiver]
    hals.push countExpressionHalstead expression.index if expression.index?
    hal = combineHalsteads hals
    hal.operators.push '[]'
    return hal
  if expression?.argv?
    hal = combineHalsteads (countExpressionHalstead arg for arg in expression.argv)
    hal.operands.push expression.callee
    hal.operators.push 'new' if expression.newAllocation?
    return hal
  if expression?.callee? and expression?.initializer?
    hal = countExpressionHalstead expression.initializer
    hal.operators.push 'new'
    hal.operators.push '{}'
    return hal
  if comparators.test expression?.operator
    hal = combineHalsteads [
      countExpressionHalstead expression.left
      countExpressionHalstead expression.right
    ]
    hal.operators.push expression.operator
    return hal
  if assigners.test expression?.operator
    hal = countExpressionHalstead expression.value
    hal.operators.push expression.operator
    hal.operands.push expression.name
    return hal
  if operators.test expression?.operator
    hal = combineHalsteads [
      countExpressionHalstead expression.left
      countExpressionHalstead expression.right
    ]
    hal.operators.push expression.operator
    return hal
  if expression?.condition?
    hal = combineHalsteads [
      countExpressionHalstead expression.condition
      countExpressionHalstead expression.trueValue
      countExpressionHalstead expression.falseValue
    ]
    hal.operators.push '?:'
    return hal
  return {
    operators: []
    operands: [expression]
  }

calculateStatementComplexity = (statement, options) ->
  cnf = options.conditionalNestFactor
  lnf = options.loopNestFactor
  cc = 0
  switch statement.statement
    when "return"
      cc = 1 + calculateExpressionComplexity statement.returns, options
    when "throw"
      cc = calculateExpressionComplexity statement.throws, options
    when "declaration"
      cc = if statement.initializer? then 1 + calculateExpressionComplexity statement.initializer else 0
    when "assignment", "prefix", "postfix", "methodCall"
      cc = calculateExpressionComplexity statement.expression, options
    when "if"
      cc = if statement.elseBlock? then 2 else 1
      cc += calculateExpressionComplexity statement.condition, options
      cc += cnf * calculateStatementComplexity statement.block, options
      cc += cnf * calculateStatementComplexity statement.elseBlock, options if statement.elseBlock?
    when "while", "do_while"
      cc = 1
      cc += calculateExpressionComplexity statement.condition, options
      cc += lnf * calculateStatementComplexity statement.block, options
    when "for"
      cc = 1
      if statement.initializer?
        cc += calculateExpressionComplexity statement.initializer, options
        cc += calculateExpressionComplexity statement.condition, options
        cc += calculateExpressionComplexity statement.increment, options
      else
        cc += calculateExpressionComplexity statement.domain, options
      cc += lnf * calculateStatementComplexity statement.block, options
    when "dml"
      if statement.operation is 'merge'
        cc = calculateExpressionComplexity statement.left, options
        cc += calculateExpressionComplexity statement.right, options
      else
        cc = calculateExpressionComplexity statement.expression, options
    when "block"
      cc = calculateBlockComplexity statement.block, options
    else 0
  return cc

countStatementHalstead = (statement) ->
  switch statement.statement
    when "return"
      combineHalsteads (countExpressionHalstead ret for ret in statement.returns)
    when "throw"
      countExpressionHalstead statement.throws
    when "declaration"
      hal = if statement.initializer? then countExpressionHalstead statement.initializer else
        operators: []
        operands: []
      hal.operands.push statement.name
      if statement.type.container?
        if statement.type.container is '[]'
          hal.operands.push "#{statement.type.contains}[]"
        else
          hal.operands.push "#{statement.type.container}<#{statement.type.contains}>"
      else
        hal.operands.push statement.type
      hal.operators.push '=' if statement.initializer?
      hal
    when "assignment", "prefix", "postfix", "methodCall"
      countExpressionHalstead statement.expression
    when "if"
      hals = [
        countExpressionHalstead statement.condition
        countStatementHalstead statement.block
      ]
      hals.push countStatementHalstead statement.elseBlock if statement.elseBlock?
      hal = combineHalsteads hals
      hal.operators.push 'if'
      hal.operators.push 'else' if statement.elseBlock?
      hal
    when "while", "do_while"
      hal = combineHalsteads [
        countExpressionHalstead statement.condition
        countStatementHalstead statement.block
      ]
      hal.operators.push statement.statement
      hal
    when "for"
      if statement.initializer?
        hals = [
          countExpressionHalstead statement.intializer
          countExpressionHalstead statement.condition
          countExpressionHalstead statement.increment
        ]
      else
        hals = [
          countExpressionHalstead statement.domain
        ]
      hals.push countStatementHalstead statement.block
      hal = combineHalsteads hals
      hal.operators.push 'for'
      hal
    when "dml"
      if statement.operation is 'merge'
        hal = combineHalsteads [
          countExpressionHalstead statement.left
          countExpressionHalstead statement.right
        ]
      else
        hal = countExpressionHalstead statement.expression
      hal.operators.push statement.operation
      hal
    when "block"
      countBlockHalstead statement.block
    else
        operators: []
        operands: []

calculateBlockComplexity = (block, options) ->
  cc = 0
  for statement in block
    cc += calculateStatementComplexity statement, options
  cc

combineHalsteads = (hals) ->
  hal =
    operators: []
    operands: []
  for oneHal in hals
    hal.operators = hal.operators.concat oneHal.operators
    hal.operands = hal.operands.concat oneHal.operands
  hal

countBlockHalstead = (block) ->
  combineHalsteads (countStatementHalstead statement for statement in block)

calculateComplexity = (methodBody, options) ->
  options ?= {}
  options.conditionalNestFactor ?= 1
  options.loopNestFactor ?= 1
  cc = calculateBlockComplexity methodBody, options
  cc += 1 if methodBody[methodBody.length-1].statement isnt 'return'
  cc

countHalstead = (methodBody) ->
  countBlockHalstead methodBody

lineCount = (pos) ->
  pos.last_line - pos.first_line + 1

sum = (vals) ->
  s = (s or 0) + v for v in vals
  s

analyzeClass = (cls) ->
  metrics = {}
  metrics.methods = for m in cls.body when m.member is 'method'
      name: m.name
      lines: lineCount m.position
      parameters: m.parameters.length
      statements: m.body.length
      complexity: calculateComplexity m.body
      nestWeightedComplexity: calculateComplexity(m.body,
        conditionalNestFactor: NEST_FACTOR
        loopNestFactor: NEST_FACTOR
      )
      halstead: countHalstead m.body
  metrics.methodCount = metrics.methods.length
  metrics.propertyCount = (m for m in cls.body when m.member is 'property').length
  metrics.innerClassCount = (m for m in cls.body when m.member is 'inner_class').length
  metrics.lines = cls.position.last_line+1 # due to a bug in the ascent parser position information
  metrics.linesPerMethod = metrics.lines / metrics.methodCount
  metrics.statements = sum(m.statements for n, m of metrics.methods)
  metrics.complexity = sum(m.complexity for n, m of metrics.methods)
  metrics.complexityPerMethod = metrics.complexity / metrics.methodCount
  metrics.complexityPerLine = metrics.complexity / metrics.lines
  metrics

module.exports =
  analyze: analyzeClass
