using afIoc::Inject
using afIoc::Registry
using web::WebReq


** Because [WebReq]`web::WebReq` isn't 'const'
** 
** This is proxied and always refers to the current request
const mixin Request {

	** The uri relative to `BedSheetWebMod`
	abstract Uri modRel()

	** The uri relative to the `Route`
	abstract Uri routeRel()
	
	abstract Route route()
	
}

//@NoDoc
internal const class RequestImpl : Request {
	
	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) } 

	override Uri modRel() {
		webReq.modRel
	}
	
	override Uri routeRel() {
		relPath := route.pattern.replace("*", "").toUri
		absPath := modRel[relPath.path.size..-1]
		return absPath
	}
	
	override Route route() {
		routeMatch.route
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}

	private RouteMatch routeMatch() {
		webReq.stash["bedSheet.routeMatch"]
	}
}