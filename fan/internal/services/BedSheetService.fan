using web::WebReq
using web::WebRes
using afIoc::Inject
using afIoc::ThreadStashManager
using afIoc::Registry

const internal class BedSheetService {
	private const static Log log := Utils.getLog(BedSheetService#)
	
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
			webReq.stash["bedSheet.routeMatch"] = routeMatch

			result := routeHandler.handle(routeMatch)
			processResult(result)

		} catch (Err err) {
			
			try {
				result := errHandlerSrc.getErrHandler(err).handle(err)
				processResult(result)

			} catch (Err doubleErr) {
				// the backup plan for when the err handler errs!
				log.err("ERROR in the ERR HANDLER!!!", doubleErr)
				log.err("  - Original Err", err)
				
				if (!webRes.isCommitted)
					webRes.sendErr(500, err.msg)
			}
			
		} finally {
			stashManager.cleanUp
		}
	}
	
	private Void processResult(Obj result) {
		if (result == true)
			return
		
		resPro := resProSrc.getResultProcessor(result.typeof)
		resPro.process(result)
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}
