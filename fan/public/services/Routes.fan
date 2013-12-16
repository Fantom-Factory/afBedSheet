using web
using afIoc::Inject
using afIoc::Registry

** (Service) - Handles routing URIs to request handlers.
const mixin Routes {

	** The ordered list of routes
	abstract Obj[] routes()

	** Returns true if the HTTP request was handled. 
	abstract Bool processRequest(Uri modRel, Str httpMethod)
}

internal const class RoutesImpl : Routes {
	private const static Log log := Utils.getLog(Routes#)

	override const Route[] routes

	@Inject	private const ResponseProcessors	responseProcessors  

	internal new make(Route[] routes, |This|? in := null) {
		in?.call(this)
		this.routes = routes
		if (routes.isEmpty)
			log.warn(BsLogMsgs.routesGotNone)
	}

	override Bool processRequest(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)

		// loop through all routes looking for a non-null response
		handled := routes.eachWhile |route| {
			response := route.match(normalisedUri, httpMethod)

			if (response == null)
				return null
			
			// process any non-null results
			processed := responseProcessors.processResponse(response)
			
			return processed ? true : null
		}

		return handled != null
	}

	private Uri normalise(Uri uri) {
		if (!uri.isPathAbs)
			uri = `/` + uri
		return uri
	}	
}

