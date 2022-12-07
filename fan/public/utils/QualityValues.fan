
** Parses a 'Str' of HTTP qvalues as per HTTP 1.1 Spec / 
** [rfc2616-sec14.3]`http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3`. Provides some 
** useful accessor methods; like [#accepts(Str name)]`QualityValues.accepts` which returns 'true' only if the 
** name exists AND has a qvalue greater than 0.0.
**
** @see `http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html`
class QualityValues {

	private HttpQVal[]	qVals
	
	private new fromHttpQVals(HttpQVal[] qVals) {
		this.qVals = qVals
	}
	
	** Creates a new 'QualityValues' instance from the given map.
	static new make(Str:Float qvals) {
		// used by afHaystackOps for StackHub
		http := HttpQVal[,]
		qvals.each |v, k| {
			http.add(HttpQVal("$k;q=$v"))
		}
		return fromHttpQVals(http)
	}
	
	** Parses a HTTP header value into a 'name:qvalue' map.
	** Throws 'ParseErr' if the header Str is invalid.
	** 
	**   syntax: fantom
	**   QualityValues("Accept: audio/*; q=0.2, audio/basic")
	static new fromStr(Str? header := null, Bool checked := true) {
		if (header == null)
			return QualityValues(HttpQVal[,])

		try {
			qVals := header.split(',').map |val| {
				val.isEmpty ? null : HttpQVal(val)
			}.exclude { it == null }
			return QualityValues(qVals.sortr)
			
		} catch (ParseErr pe) {
			if (checked) throw pe
			return null
		}
	}

	** Returns a joined-up Str of qvalues that may be set in a HTTP header. The names are sorted by 
	** qvalue. Example:
	**
	**   audio/*; q=0.2, audio/basic
	override Str toStr() {
		qVals.join(", ")
	}

	** Returns the qvalue associated with 'name'. Defaults to '0' if 'name' was not supplied.
	** 
	** This method matches against '*' wildcards in the qvalue list, but favours exact match.
	@Operator
	Float get(Str name) {
		vals := HttpQVal#.emptyList as HttpQVal[]

		// favour an exact match before a wildcard match
		if (vals.isEmpty)
			vals = qVals.findAll { it.fullName == name }.sortr
		
		if (vals.isEmpty)
			vals = qVals.findAll { it.accepts(name) }.sortr
		
		if (vals.isEmpty)
			return 0f
	
		partialMatch := vals.find { it.name.startsWith("*") == false }
		if (partialMatch != null)
			return partialMatch.quality ?: 1f

		return vals.first.quality ?: 1f
	}

	** Returns 'true' if 'name' was supplied in the header.
	** 
	** This method matches against '*' wildcards in the qvalue list.
	Bool contains(Str name) {
		qVals.any { it.matches(name) }
	}

	** Returns 'true' if the name was supplied in the header AND has a qvalue > 0.0
	** 
	** This method matches against '*' wildcards in the qvalue list.
	Bool accepts(Str name) {
		qVals.any { it.accepts(name) }
	}
	
	** Returns the number of values given in the header
	Int size() {
		qVals.size
	}
	
	** Returns 'size() == 0'
	Bool isEmpty() {
		qVals.isEmpty
	}
	
	** Clears the qvalues
	Void clear() {
		qVals.clear
	}
	
	@NoDoc @Deprecated { msg="Use 'qvalues' instead" } 
	Str:Float toMap() {
		qvalues
	}
	
	** Returns a dup of the internal 'name:qvalue' map.
	** 
	** Use 'get()' and 'set()' to modify qvalues.
	Str:Float qvalues() {
		val := Str:Float[:]
		val.ordered = true
		qVals.each { val[it.fullName] = it.quality ?: 1f }
		return val
	}
}

internal class HttpQVal {
	
	Str			name
	[Str:Str]?	params
	Float?		quality
	
	new fromStr(Str val) {
		idx := val.index(";")
		
		if (idx == null) {
			this.name = val
			return
		}
		
		params := MimeType.parseParams(val[idx+1..-1], true)
		if (params.containsKey("q") == false) {
			this.name = val
			return
		}
		
		qnum := params.remove("q").toFloat(false)
		if (qnum == null)
			throw ParseErr("q is not a float: $val")
		if (qnum < 0.0f || qnum > 1.0f)
			throw ParseErr("q should be 0..1: $val")

		this.name		= val[0..<idx]
		this.quality	= qnum
		if (params.size > 0)
			this.params = params
	}
	
	Bool matches(Str name) {
		Regex.glob(this.name).matches(name)
	}
	
	Bool accepts(Str name) {
		Regex.glob(this.name).matches(name) && (quality == null || quality > 0f)
	}
	
	Str fullName() {
		params == null
			? name
			: name + ";" + params.join(";") |v, k| {
				v.isEmpty ? k : "${k}=${v}"
			}
	}
	
	override Int compare(Obj obj) {
		that := (HttpQVal) obj
		if (this.quality != that.quality)
			return (this.quality ?: 1f) <=> (that.quality ?: 1f)
		
		if (this.name != that.name)
			return this.name <=> that.name
		
		// params trump non-params
		if (this.params != null && that.params == null)
			return -1

		return 0
	}
	
	override Str toStr() {
		quality == null
			? fullName
			: fullName + ";q=" + quality.toLocale("0.0##")
	}
}
