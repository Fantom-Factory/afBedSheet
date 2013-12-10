using web
using afIoc::Inject
using afIoc::Registry

** (Service) - Handles routing URIs to request handler methods.
**
** If a uri can not be matched to a `Route` then a 404 HttpStatusErr is thrown.
const mixin Routes {

	** The ordered list of routes
	abstract Obj[] routes()
	
	@NoDoc
	abstract Obj processRequest(Uri modRel, Str httpMethod)
}

internal const class RoutesImpl : Routes {
	private const static Log log := Utils.getLog(Routes#)

	override const Route[] routes

	@Inject	private const Registry registry


	internal new make(Route[] routes, |This|? in := null) {
		in?.call(this)
		this.routes = routes
		if (routes.isEmpty)
			log.warn(BsLogMsgs.routesGotNone)
	}

	override Obj processRequest(Uri modRel, Str httpMethod) {
		normalisedUri := normalise(modRel)
		
		// loop through all routes looking for a non-null response
		response := routes.eachWhile |route| {
			response := route.match(normalisedUri, httpMethod)			
			return (response == false) ? null : response
		}

		// if no routes have been defined, return the default 'BedSheet Welcome' page
		if (response == null && routes.isEmpty)
			return ((WelcomePage) registry.autobuild(WelcomePage#)).service

		if (response == null)
			throw HttpStatusErr(404, BsErrMsgs.route404(modRel, httpMethod))

		return response
	}

	private Uri normalise(Uri uri) {
		if (!uri.isPathAbs)
			uri = `/` + uri
		return uri
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}	
}

