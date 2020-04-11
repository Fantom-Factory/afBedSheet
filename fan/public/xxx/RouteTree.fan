
class RouteTree {

	private Str:Obj			handlers
	private Str:RouteTree	childTrees
	
	new make() {
		handlers	= Str:Obj[:]
		childTrees	= Str:RouteTree[:]
	}
	
	@Operator
	This set(Str[] segments, Obj handler) {
		depth	:= segments.size
		urlKey	:= segments.first.lower

		if (depth == 1) {
			handlers[urlKey] = handler

		} else {
			childTree := childTrees[urlKey]
			if (childTree == null)
				childTrees[urlKey] = childTree = RouteTree()
			childTree[segments[1..-1]] = handler
		}

		return this
	}

	@Operator
	internal Route3? get(Str[] segments) {
		depth	:= segments.size
		segment	:= segments.first
		urlKey	:= segment.lower

		if (depth == 1) {

			handler := handlers[urlKey]
			if (handler != null) {
				route := Route3(handler, urlKey)
				return route
			}

//			handlerMatch = handlers["**"]
//			if (handlerMatch != null) {
//				return Route2(url, `**`, `/` + workingUri.lower.toUri, handlerMatch, [url.path[0]], [url.path[0]])
//			}

			handler = handlers["*"]
			if (handler != null) {
				route := Route3(handler, urlKey)
				route.wildcards.insert(0, segment)
				return route
			}

		} else if (depth > 1) {

			childTree := childTrees[urlKey]
			if (childTree != null) {
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, urlKey)
				}
				return route
			}

//			handlerMatch := handlers["**"]
//			if (handlerMatch != null) {
//				Str[] wildCardList := url.path
//				return Route2(url, `**`, Uri.fromStr(url.toStr.lower), handlerMatch, wildCardList, wildCardList)
//			}

			childTree = childTrees["*"]
			if (childTree != null) {
				
				route := childTree[segments[1..-1]]
				if (route != null) {
					route.canonical.insert(0, urlKey)
					route.wildcards.insert(0, segment)
				}
				return route
				
//				routeMatch = matchHandler.get(Uri.fromStr("/" + url.getRange(1..-1).toStr))
//				
//				routeMatch.wildcardSegments = routeMatch.wildcardSegments.rw.insert(0, Uri.fromStr(url.path[0]).path[0])
//				
//				routeMatch.canonicalUrl = Uri.fromStr("/" + workingUri + routeMatch.canonicalUrl.toStr)
//				routeMatch.requestUrl = url
//				return routeMatch
			}
		}

		return null
    }
}
