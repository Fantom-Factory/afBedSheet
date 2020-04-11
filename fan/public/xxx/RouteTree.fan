
class RouteTree {

	private Str:Obj			handlerMap	:= Str:Obj[:]
	private Str:RouteTree	nestedMap	:= Str:RouteTree[:]
	
	
	@Operator
	This set(Uri url, Obj handler) {
		if (url.pathStr.contains("//"))	throw ArgErr("That's nasty! $url")

		childRouteTree := (RouteTree?) null
        	routeStr	:= url.pathStr
		routeDepth	:= url.path.size
		workingUri := url.path[0].lower

		if (routeDepth == 1) {
			handlerMap[workingUri.toStr] = handler
		} else {

			// --> FAN use Map.getOrAdd(...)
			childRouteTree = nestedMap[workingUri.toStr]

			if (childRouteTree == null) {
				childRouteTree = RouteTree()
				nestedMap[workingUri.toStr] = childRouteTree
			}
			childRouteTree[url[1..-1]] = handler
		}
        return this
    }

	// List out all absoluteMaps
	Str:RouteTree getHandlerMap() { return handlerMap }

	// List out all absoluteMaps
	Str:RouteTree getNestedMap() { return nestedMap }

    @Operator
    Route2? get(Uri url) {
		matchHandler := (RouteTree?) null
		workingUri := url.path[0].lower
		handlerMatch := null
		routeMatch := (Route2?) null
		routeDepth	:= url.path.size
		if (routeDepth == 1) {

			handlerMatch = handlerMap[workingUri]

			if (handlerMatch != null) {
				return Route2(url, workingUri.toUri, `/` + workingUri.toUri,handlerMatch, Str[,], Str[,])
			}

			handlerMatch = handlerMap["**"]

			if (handlerMatch != null) {
				return Route2(url, `**`, `/` + workingUri.lower.toUri, handlerMatch, [url.path[0]], [url.path[0]])
			}

			handlerMatch = handlerMap["*"]

			if (handlerMatch != null) {
				return Route2(url, `*`, `/` + workingUri.toUri, handlerMatch, Uri.fromStr(url.path[0]).path, Str[,])
			}
		} else if (routeDepth > 1) {
			matchHandler = nestedMap[workingUri]
			if (matchHandler != null) {
				routeMatch = matchHandler[url[1..-1]]
				
				if (routeMatch != null) {
					
					if (!routeMatch.canonicalUrl.isPathAbs) {
						routeMatch.canonicalUrl = Uri.fromStr("/" + workingUri + "/" + routeMatch.canonicalUrl.toStr)
					} else {
						routeMatch.canonicalUrl = Uri.fromStr("/" + workingUri + routeMatch.canonicalUrl.toStr)
					}
					routeMatch.requestUrl = url
					
				}
				return routeMatch
			}

			handlerMatch = handlerMap["**"]

			if (handlerMatch != null) {
				Str[] wildCardList := url.path
				return Route2(url, `**`, Uri.fromStr(url.toStr.lower), handlerMatch, wildCardList, wildCardList)
			}

			matchHandler = nestedMap["*"]

			if (matchHandler != null) {
				routeMatch = matchHandler.get(Uri.fromStr("/" + url.getRange(1..-1).toStr))
				
				routeMatch.wildcardSegments = routeMatch.wildcardSegments.rw.insert(0, Uri.fromStr(url.path[0]).path[0])
				
				routeMatch.canonicalUrl = Uri.fromStr("/" + workingUri + routeMatch.canonicalUrl.toStr)
				routeMatch.requestUrl = url
				return routeMatch
			}
		}

		return null
    }
}
