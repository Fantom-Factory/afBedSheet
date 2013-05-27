using web::WebReq
using afIoc::Inject
using afIoc::ThreadStashManager
using afIoc::Registry

const internal class BedSheetService {
	
	@Inject	private const Registry				registry
	@Inject	private const ThreadStashManager 	stashManager
	@Inject	private const Request 				req
	@Inject	private const RouteHandler 			routeHandler
	@Inject	private const Router 				router
	@Inject	private const ResultProcessorSource	resProSrc
	@Inject	private const ErrHandlerSource		errHandlerSrc
	
	new make(|This|in) { in(this) }
	
	Void service() {

		try {
			routeMatch	:= router.match(req.modRel, req.httpMethod)

			// save the routeMatch so it can be picked up by `Request`
			webReq := (WebReq) registry.dependencyByType(WebReq#)
			webReq.stash["bedSheet.routeMatch"] = routeMatch

			if (routeMatch == null)
				throw HttpStatusErr(404, BsMsgs.routeNotFound(req.modRel))

			result	:= routeHandler.handle(routeMatch)

			// TODO: true is okay, void is warn, null is err
			if (result != null) {
				resPro 		:= resProSrc.getResultProcessor(result.typeof)
				resPro.process(result)
			}

		} catch (Err err) {

			errHandlerSrc.getErrHandler(err).handle(err)

			// what when no err handler matches!?
			
			// TODO: have backup plan for when the err handler errs!
			
//			buf:=StrBuf()
//			err.trace(Env.cur.out, ["maxDepth":500])
			
		} finally {
			stashManager.cleanUp
		}
	}
}
