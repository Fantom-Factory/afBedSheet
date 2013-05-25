using afIoc::Inject
using afIoc::Registry
using web::WebReq


** Because [WebReq]`web::WebReq` isn't 'const'
** 
** This is proxied and always referes to the current request
const mixin Request {

	abstract Uri modRel()

//	abstract Uri routeRel()
	
}

//@NoDoc
internal const class RequestImpl : Request {
	
	@Inject
	private const Registry registry
	
	new make(|This|in) { in(this) } 

	override Uri modRel() {
		webReq.modRel
	}
	
//	override Uri routeRel() {
//		
//	}
	
	private WebReq? webReq() {
		registry.dependencyByType(WebReq#)
	}
}