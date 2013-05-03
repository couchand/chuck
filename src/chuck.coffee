# chuck, because, why not?

NEST_FACTOR = 2

comparators = /\|\||&&|!=|==|!==|===|<|<=|>|>=/
assigners = /\=|\+=|-=|\*=|\/=|\+\+|--/
operators = /\+|-|\*|\//

calculateExpressionComplexity = (expression) ->
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

calculateStatementComplexity = (statement) ->
  cc = 0
  switch statement.statement
    when "return"
      cc = 1 + calculateExpressionComplexity statement.returns
    when "throw"
      cc = calculateExpressionComplexity statement.throws
    when "declaration"
      cc = if statement.initializer? then 1 + calculateExpressionComplexity statement.initializer else 0
    when "assignment", "prefix", "postfix", "methodCall"
      cc = calculateExpressionComplexity statement.expression
    when "if"
      cc = if statement.elseBlock? then 2 else 1
      cc += calculateExpressionComplexity statement.condition
      cc += NEST_FACTOR * calculateStatementComplexity statement.block
      cc += NEST_FACTOR * calculateStatementComplexity statement.elseBlock if statement.elseBlock?
    when "while", "do_while"
      cc = 1
      cc += calculateExpressionComplexity statement.condition
      cc += NEST_FACTOR * calculateStatementComplexity statement.block
    when "for"
      cc = 1
      if statement.initializer?
        cc += calculateExpressionComplexity statement.initializer
        cc += calculateExpressionComplexity statement.condition
        cc += calculateExpressionComplexity statement.increment
      else
        cc += calculateExpressionComplexity statement.domain
      cc += NEST_FACTOR * calculateStatementComplexity statement.block
    when "dml"
      if statement.operation is 'merge'
        cc = calculateExpressionComplexity statement.left
        cc += calculateExpressionComplexity statement.right
      else
        cc = calculateExpressionComplexity statement.expression
    when "block"
      cc = calculateBlockComplexity statement.block
    else 0
  return cc

calculateBlockComplexity = (block) ->
 cc = 0
 for statement in block
   cc += calculateStatementComplexity statement
 cc

calculateComplexity = (methodBody) ->
  cc = calculateBlockComplexity methodBody
  cc += 1 if methodBody[methodBody.length-1].statement isnt 'return'
  cc

lineCount = (pos) ->
  pos.last_line - pos.first_line + 1

sum = (vals) ->
  s = (s or 0) + v for v in vals
  s

analyzeClass = (cls) ->
  metrics = {}
  metrics.methods = {}
  metrics.methodCount = 0
  for m in cls.body when m.member is 'method'
    metrics.methodCount++
    metrics.methods[m.name] =
      lines: lineCount m.position
      parameters: m.parameters.length
      statements: m.body.length
      complexity: calculateComplexity m.body
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
