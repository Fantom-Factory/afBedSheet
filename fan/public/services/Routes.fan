using web
using afIoc::Inject
using afIoc::Registry

** (Service) - Contribute your `Route` objects to this.
** 
** Responsible for routing URIs to request handlers.
** 
** @uses a Configuration of 'Route[]'
@NoDoc	// don't overwhelm the masses!
const mixin Routes {

	** The ordered list of routes
	abstract Route[] routes()

	** Returns true if the HTTP request was handled.
	@NoDoc	// not for public use 
	abstract Bool processRequest(HttpRequest httpRequest)
}

internal const class RoutesImpl : Routes {
	private const static Log log := Utils.getLog(Routes#)

	override const Route[] routes

	@Inject	private const ResponseProcessors	responseProcessors  

	internal new make(Obj[] routes, |This|? in := null) {
		in?.call(this)
		rs := routes.flatten
		this.routes = rs.map |route->Route| {
			if (route isnot Route)
				throw ArgErr(BsErrMsgs.routes_wrongType(route))
			return route
		}
		if (routes.isEmpty)
			log.warn(BsLogMsgs.routes_gotNone)
	}

	override Bool processRequest(HttpRequest httpRequest) {
		// loop through all routes looking for a non-null response
		handled := routes.eachWhile |route| {
			response := route.match(httpRequest)

			if (response == null)
				return null
			
			// process any non-null results
			processed := responseProcessors.processResponse(response)
			
			return processed ? true : null
		}

		return handled != null
	}
}

