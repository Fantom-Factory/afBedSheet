
internal class RouteTreeBuilder {
	private Str:RouteTreeBuilder	childTrees
	private Str:Obj					handlers
	
	new make() {
		this.childTrees	= Str:RouteTreeBuilder[:]
		this.handlers	= Str:Obj[:]
	}
	
	@Operator
	This set(Str[] segments, Obj handler) {
		depth	:= segments.size
		urlKey	:= segments.first.lower

		if (depth == 1) {
			handlers[urlKey] = handler

		} else {
			if (urlKey == "**")
				throw Err("Double wildcards can only be the last segment: $segments")
			
			childTree := childTrees[urlKey]
			if (childTree == null)
				// use add so we don't overwrite
				childTrees.add(urlKey, childTree = RouteTreeBuilder())
			childTree[segments[1..-1]] = handler
		}

		return this
	}
	
	@Operator	// stoopid fantom
	RouteMatch? get(Str[] segments) { null }
	
	RouteTree toConst() {
		constTrees := this.childTrees.map { it.toConst }
		return RouteTree(constTrees, handlers)
	}
}

internal const class RouteTree {
	private const Str:RouteTree	childTrees
	private const Str:Obj		handlers
	
	new make(Str:RouteTree childTrees, Str:Obj handlers) {
		this.childTrees	= childTrees.toImmutable
		this.handlers	= handlers.toImmutable
	}

	@Operator
	RouteMatch? get(Str[] segments) {
		depth	:= segments.size
		segment	:= segments.first
		urlKey	:= segment.lower

		if (depth == 1) {

			handler := handlers[urlKey]
			if (handler != null) {
				route := RouteMatch(handler)
				route.canonical.insert(0, urlKey)
				return route
			}

			handler = handlers["*"]
			if (handler != null) {
				route := RouteMatch(handler)
				route.canonical.insert(0, urlKey)
				route.wildcards.insert(0, segment)
				return route
			}

		} else {

			childTree := childTrees[urlKey]
			if (childTree != null) {
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, urlKey)
				}
				return route
			}

			childTree = childTrees["*"]
			if (childTree != null) {
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, urlKey)
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
				route.canonical.add(segments[i].lower)
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

	Uri canonicalUrl() {
		url := ``
		for (i := 0; i < canonical.size; ++i) {
			url = url.plusSlash.plusName(canonical[i])
		}
		return url
	}
}
