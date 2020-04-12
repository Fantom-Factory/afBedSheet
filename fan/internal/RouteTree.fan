
internal class RouteTreeBuilder {
	private Str:RouteTreeBuilder	childTrees
	private Str:Obj					handlers
	private Str:Str					canonicalNames 
	
	new make() {
		this.childTrees		= Str:RouteTreeBuilder[:]	{ it.caseInsensitive = true }
		this.handlers		= Str:Obj[:] 				{ it.caseInsensitive = true }
		this.canonicalNames	= Str:Str[:] 				{ it.caseInsensitive = true }
	}
	
	@Operator
	This set(Str[] segments, Obj handler) {
		depth	:= segments.size
		segment	:= segments.first ?: ""

		if (depth <= 1) {
			handlers		[segment] = handler
			canonicalNames	[segment] = segment

		} else {
			if (segment == "**")
				throw Err("Double wildcards MUST be the last segment: $segments")
			
			childTree := childTrees[segment]
			if (childTree == null)
				// use "add()" so we don't overwrite
				childTrees.add(segment, childTree = RouteTreeBuilder())
			childTree[segments[1..-1]] = handler
			canonicalNames[segment] = segment
		}

		return this
	}
	
	@Operator	// stoopid fantom
	RouteMatch? get(Str[] segments) { null }
	
	RouteTree toConst() {
		constTrees := this.childTrees.map { it.toConst }
		return RouteTree(constTrees, handlers, canonicalNames)
	}
}

internal const class RouteTree {
	private const Str:Str		canonicalNames
	private const Str:RouteTree	childTrees
	private const Str:Obj		handlers
	
	new make(Str:RouteTree childTrees, Str:Obj handlers, Str:Str canonicalNames) {
		this.childTrees		= childTrees	.toImmutable
		this.handlers		= handlers		.toImmutable
		this.canonicalNames	= canonicalNames.toImmutable
	}

	@Operator
	RouteMatch? get(Str[] segments) {
		depth	:= segments.size
		segment	:= segments.first ?: ""

		if (depth <= 1) {

			handler := handlers[segment]
			if (handler != null) {
				route := RouteMatch(handler)
				route.canonical.insert(0, canonicalNames[segment])
				return route
			}

			handler = handlers["*"]
			if (handler != null) {
				route := RouteMatch(handler)
				route.canonical.insert(0, segment)
				route.wildcards.insert(0, segment)
				return route
			}

		} else {

			childTree := childTrees[segment]
			if (childTree != null) {
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, canonicalNames[segment])
				}
				return route
			}

			childTree = childTrees["*"]
			if (childTree != null) {
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, segment)
					route.wildcards.insert(0, segment)
				}
				return route
			}
		}

		handler := handlers["**"]
		if (handler != null) {
			route	  := RouteMatch(handler)
			wildcard  := ``
			for (i := 0; i < segments.size; ++i) {
				wildcard = wildcard.plusSlash.plusName(segments[i])
				route.canonical.add(segments[i])
			}
			route.wildcards.insert(0, wildcard)
			
			return route
		}

		return null
    }
}

internal class RouteMatch {
    Obj		handler
	Str[]	canonical
    Obj[]	wildcards

	new make(Obj handler) {
		this.handler	= handler
		this.canonical	= Str[,]
		this.wildcards	= Obj[,]
	}

	** 'canonicalUrl' is what the handler was SET with
	Uri canonicalUrl() {
		url := ``
		for (i := 0; i < canonical.size; ++i) {
			url = url.plusSlash.plusName(canonical[i])
		}
		return url
	}
}
