
class Expression
	toString: -> throw "unimplemented"
	toTex: -> throw "unimplemented"
	clone: -> throw "unimplemented"
	# Returns whether `this` is a pattern which matches `expr`
	# `o` is an initial empty object which is filled with values for each Symbol id
	# If two Symbols have the same id, match() is called on the existing expression in the `o` object
	match: (expr, o) ->
		expr instanceof @constructor
	# Returns an expression with the rule's pattern replaced with the rule's replacement
	replace: (rules) ->
		for rule in rules
			o = {}
			if rule.pattern.match(@, o)
				if rule.replacement instanceof Function
					return rule.replacement(o)
				else
					# TODO Replace patterns with `o` values
					return rule.replacement.clone()
		@


class Numeric extends Expression
	constructor: (@value) ->
		if !isFinite(@value)
			throw "Number is not finite"
	toString: -> @value.toString()
	toTex: -> @toString()
	clone: ->
		new Numeric(@value)
	match: (expr, o) ->
		return false unless super
		pattern.value == @value


class Symbol extends Expression
	constructor: (@name) ->
	toString: -> @name

	texGreek: "alpha nu beta xi Xi gamma Gamma delta Delta pi Pi epsilon varepsilon rho varrho zeta sigma Sigma eta tau theta vartheta Theta upsilon Upsilon iota phi varphi Phi kappa chi lambda Lambda psi Psi mu omega Omega".split(' ')
	toTex: ->
		if @texGreek.indexOf(@name) >= 0
			return "\\#{@name}"
		else if @name.length > 1
			return "\\text{#{@name}}"
		else
			return @name
	clone: ->
		new Symbol(@name)
	match: (expr, o) ->
		return false unless super
		expr.name == @name


class Func extends Expression
	constructor: (@func, @args=[]) ->
	toString: ->
		argsStr = @args.map((arg) -> arg.toString()).join(", ")
		"#{@func.toString()}[#{argsStr}]"
	toTex: ->
		if @func instanceof Symbol
			sym = builtinSymbols[@func.name]
			if sym && sym.funcToTex
				return sym.funcToTex(@args)
		argsStr = @args.map((arg) -> arg.toTex()).join(", ")
		"#{@func.toTex()}[#{argsStr}]"
	clone: ->
		argsClone = @args.map((arg) -> arg.clone())
		new Func(@func.clone(), argsClone)
	match: (expr, o) ->
		return false unless expr instanceof Func
		return false unless @func.match(expr.func, o)
		return false unless @args.length == expr.args.length
		for i in [0...@args.length]
			return false unless @args[i].match(expr.args[i], o)
		true
	replace: (rules) ->
		@func = @func.replace(rules)
		for i in [0...@args.length]
			@args[i] = @args[i].replace(rules)
		super


class Pattern extends Expression
	constructor: ({@id, @type}) ->
	match: (expr, o) ->
		if @type
			return false unless expr instanceof @type
		if @id
			o[@id] = expr
		true


texParens = (tex) ->
	"\\left(#{tex}\\right)"

builtinSymbols =
	Times:
		funcToTex: (args) ->
			texParens args.map((arg) -> arg.toTex()).join(" \\cdot ")
	Plus:
		funcToTex: (args) ->
			texParens args.map((arg) -> arg.toTex()).join(" + ")
	Power:
		funcToTex: (args) ->
			base = args[0].toTex()
			base = if base.length == 1 then base else "{#{base}}"
			exp = args[1].toTex()
			exp = if exp.length == 1 then exp else "{#{exp}}"
			"#{base}^#{exp}"


class Rule
	constructor: (@pattern, @replacement) ->


builtinRules = [
	new Rule new Func(new Symbol('Plus'), [new Pattern(id: 'x', type: Numeric), new Pattern(id: 'y', type: Numeric)]), (o) ->
		new Numeric(o.x.value + o.y.value)
,
	new Rule new Func(new Symbol('Times'), [new Pattern(id: 'x', type: Numeric), new Pattern(id: 'y', type: Numeric)]), (o) ->
		new Numeric(o.x.value * o.y.value)
,
	new Rule new Func(new Symbol('Power'), [new Pattern(id: 'x', type: Numeric), new Pattern(id: 'y', type: Numeric)]), (o) ->
		new Numeric(Math.pow(o.x.value, o.y.value))
]


simplify = (expr) ->
	expr.replace(builtinRules)
