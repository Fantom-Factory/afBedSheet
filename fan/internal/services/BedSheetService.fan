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
//	@Inject	private const RouteHandler 			routeHandler
	@Inject	private const Routes				routes
	@Inject	private const ResultProcessorSource	resProSrc
	@Inject	private const ErrProcessorSource	errProSrc
	
	new make(|This|in) { in(this) }
	
	Void service() {
		try {
			result	:= routes.processRequest(req.modRel, req.httpMethod)

//			// save the routeMatch so it can be picked up by `Request` for routeBase() & routeMod()
//			webReq.stash["bedSheet.routeMatch"] = routeMatch
//
//			result := routeHandler.handle(routeMatch)
			if (result != true)
				resProSrc.process(result)

		} catch (Err err) {
			
			try {
				result := errProSrc.process(err)
				// TODO: more recursive handling...
				if (result != true)
					resProSrc.process(result)

			} catch (Err doubleErr) {
				// the backup plan for when the err handler errs!
				log.err("ERROR in the ERR HANDLER!!!", doubleErr)
				log.err("  - Original Err", err)
				
//		b := Buf()	// can't trace to a StrBuf
//		err.trace(b.out, ["maxDepth":250])
//		es:=b.flip.in.readAllStr
//		Env.cur.err.printLine(es)
				
				if (!webRes.isCommitted)
					webRes.sendErr(500, err.msg)
			}
			
		} finally {
			stashManager.cleanUpThread
		}
	}
	
	private WebReq webReq() {
		registry.dependencyByType(WebReq#)
	}
	
	private WebRes webRes() {
		registry.dependencyByType(WebRes#)
	}
}
