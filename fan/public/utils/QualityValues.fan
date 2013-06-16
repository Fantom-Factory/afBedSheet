
** Parses a 'Str' of HTTP qvalues as per HTTP 1.1 Spec / rfc2616-sec14.3. Provides some useful 
** accessor methods; like [#accept(Str name)]`#accept` which returns 'true' only if the name exists
** AND has a qvalue greater than 0.0.
**
** @see `http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3`
class QualityValues {
	private Str:Float	qvalues	:= Utils.makeMap(Str#, Float#)
	
	private new make(Str:Float qvalues) {
		this.qvalues = qvalues
	}
	
	** Parses a HTTP header value into a [name:qvalue] map.
	** Throws 'ParseErr' if the header Str is invalid.
	static new fromStr(Str? header, Bool checked := true) {
		qvalues	:= Utils.makeMap(Str#, Float#)
		
		if (header == null)
			return QualityValues(qvalues)

		try {
			header.split(',').each |val| {
				vals := val.split(';')
				
				if (vals.size == 1) {
					qvalues[vals[0]] = 1.0f
					return
				}
				
				if (vals.size == 2) {
					qval := vals[1]
					if (!qval.lower.startsWith("q="))
						throw ParseErr("'$qval' should start with 'q='")
					qnum := qval[2..-1].toFloat
					if (qnum < 0.0f || qnum > 1.0f)
						throw ParseErr("'$qnum' should be 0.0 >= q <= 1.0")
					qvalues[vals[0]] = qnum
					return
				}
				
				throw ParseErr("'$val' contains too many ';'")
			}

			return QualityValues(qvalues)
			
		} catch (ParseErr pe) {
			if (checked) throw pe
			return null
		}
	}

	** Returns a joined-up Str of qvalues that may be set in a HTTP header. The names are sorted by 
	** qvalue. 
	override Str toStr() {
		qvalues.keys.sortr |q1, q2| { qvalues[q1] <=> qvalues[q2] }.join(", ") |q| { qvalues[q] == 1.0f ? "$q" : "$q;q=" + qvalues[q].toLocale("0.###") }
	}

	** Returns the qvalue associated with 'name'. Defaults to '0' if 'name' was not supplied.
	@Operator
	Float get(Str name) {
		qvalues.get(name, 0f)
	}

	** Returns 'true' if 'name' was supplied in the header
	Bool contains(Str name) {
		qvalues.containsKey(name)
	}

	** Returns 'true' if the name was supplied in the header AND has a qvalue > 0.0
	Bool accepts(Str name) {
		get(name) > 0f
	}
	
	** Returns the number of values given in the header
	Int size() {
		qvalues.size
	}
	
	** Returns a dup of the internal [name:qvalue] map 
	Str:Float toMap() {
		qvalues.dup
	}
}