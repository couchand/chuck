# chuck, because, why not?

NEST_FACTOR = 2

comparators = /\|\||&&|!=|==|!==|===|<|<=|>|>=/
assigners = /\=|\+=|-=|\*=|\/=|\+\+|--/
operators = /\+|-|\*|\//

resolveContainer = (type) ->
  if type.container?
    contains = (resolveContainer t for t in [].concat type.contains).join ', '
    if type.container is '[]'
      "#{contains}[]"
    else
      "#{type.container}<#{contains}>"
  else
    type

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
    return calculateExpressionComplexity expression.left +
           calculateExpressionComplexity expression.right
  if assigners.test expression?.operator
    return calculateExpressionComplexity expression.value
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
    hals.push countExpressionHalstead expression.field if expression.field?
    hal = combineHalsteads hals
    hal.operators.push '[]'
    return hal
  if expression?.argv?
    hals = (countExpressionHalstead arg for arg in expression.argv)
    hals.push countExpressionHalstead expression.callee
    hal = combineHalsteads hals
    hal.operators.push 'new' if expression.newAllocation?
    return hal
  if expression?.callee? and expression?.initializer?
    hals = (countExpressionHalstead init for init in expression.initializer)
    hal = combineHalsteads hals
    hal.operands.push resolveContainer expression.callee
    hal.operators.push 'new'
    hal.operators.push '{}'
    return hal
  if expression?.callee?
    hal =
      operands: [resolveContainer expression.callee]
      operators: ['{}']
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
    operands: [resolveContainer expression]
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
    when "assignment", "prefix", "postfix", "method call"
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
    when "try"
      cc = statement.catches.length
      cc += calculateStatementComplexity statement.block, options
      for catchClause in statement.catches
        cc += cnf * calculateStatementComplexity catchClause.block, options
      cc += calculateStatementComplexity statement.finallyBlock, options if statement.finallyBlock?
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
      hal.operands.push resolveContainer statement.type
      hal.operators.push '=' if statement.initializer?
      hal
    when "assignment", "prefix", "postfix", "method call"
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
    when "try"
      hals = (countStatementHalstead catchClause.block for catchClause in statement.catches)
      hals.push countStatementHalstead statement.block
      hals.push countStatementHalstead statement.finallyBlock if statement.finallyBlock?
      hal = combineHalsteads hals
      hal.operators.push 'try'
      for catchClause in statement.catches
        hal.operators.push 'catch'
        hal.operands.push resolveContainer catchClause.parameter.type
        hal.operands.push catchClause.parameter.name
      hal.operators.push 'finally' if statement.finallyBlock?
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

unique = (strs) ->
  uniq = []
  for str in strs when -1 is uniq.indexOf str
    uniq.push str
  uniq

countHalstead = (methodBody) ->
  countBlockHalstead methodBody

calculateHalstead = (all) ->
  m =
    totalOperators: all.operators.length
    totalOperands: all.operands.length
    uniqueOperators: unique(all.operators).length
    uniqueOperands: unique(all.operands).length
  m.programLength = m.totalOperators + m.totalOperands
  m.vocabularySize = m.uniqueOperators + m.uniqueOperands
  m.programVolume = m.programLength * Math.log(m.vocabularySize)/Math.log(2)
  m.difficultyLevel = (m.uniqueOperators / 2) * (m.totalOperands / m.uniqueOperands)
  m.implementationEffort = m.programVolume * m.difficultyLevel
  m.implementationTime = m.implementationEffort / 18
  m.deliveredBugs = Math.pow( m.implementationEffort, 2/3 )/3000
  m

lineCount = (pos) ->
  pos.last_line - pos.first_line + 1

sum = (vals) ->
  s = (s or 0) + v for v in vals
  s

analyzeClass = (cls) ->
  metrics = {}
  metrics.methods = []
  hals = []
  for m in cls.body when m.member is 'method'
    hal = countHalstead m.body
    hals.push hal
    r =
      name: m.name
      lines: lineCount m.position
      parameters: m.parameters.length
      statements: m.body.length
      complexity: calculateComplexity m.body
      nestWeightedComplexity: calculateComplexity(m.body,
        conditionalNestFactor: NEST_FACTOR
        loopNestFactor: NEST_FACTOR
      )
      halstead: calculateHalstead hal
    metrics.methods.push r
  metrics.methodCount = metrics.methods.length
  metrics.propertyCount = (m for m in cls.body when m.member is 'property').length
  metrics.innerClassCount = (m for m in cls.body when m.member is 'inner_class').length
  metrics.lines = cls.position.last_line+1 # due to a bug in the ascent parser position information
  metrics.linesPerMethod = metrics.lines / metrics.methodCount
  metrics.statements = sum(m.statements for n, m of metrics.methods)
  metrics.complexity = sum(m.complexity for n, m of metrics.methods) - metrics.methodCount + 1
  metrics.complexityPerMethod = metrics.complexity / metrics.methodCount
  metrics.complexityPerLine = metrics.complexity / metrics.lines
  metrics.halstead = calculateHalstead combineHalsteads hals
  metrics

module.exports =
  analyze: analyzeClass
