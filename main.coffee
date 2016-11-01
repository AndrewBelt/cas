$ = (query) -> document.querySelector(query)

$('#in').oninput = ->
	$('#out-raw').innerHTML = ""
	$('#out-tex').innerHTML = ""
	$('#simplified-raw').innerHTML = ""
	$('#simplified-tex').innerHTML = ""
	try
		expr = parser.parse(@value)
		return unless expr

		$('#out-raw').textContent = expr.toString()
		katex.render(expr.toTex(), $('#out-tex'), displayMode: true)

		expr = simplify(expr)
		$('#simplified-raw').textContent = expr.toString()
		katex.render(expr.toTex(), $('#simplified-tex'), displayMode: true)
	catch e
		$('#simplified-raw').textContent = e.message || e
