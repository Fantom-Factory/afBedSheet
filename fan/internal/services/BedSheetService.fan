using web::WebReq
using web::WebRes
using afIoc::Inject
using afIoc::ThreadStashManager
using afIoc::Registry

const internal class BedSheetService {
	private const static Log log := Utils.getLog(BedSheetService#)

	@Inject	private const Registry				registry
	@Inject	private const ThreadStashManager	stashManager
	@Inject	private const Routes				routes
	@Inject	private const ResponseProcessors	responseProcessors
	@Inject	private const ErrProcessors			errProcessors
	@Inject	private const HttpResponse			httpResponse

	new make(|This|in) { in(this) }

	Void service() {
		try {
			response := routes.processRequest(webReq.modRel, webReq.method)
			responseProcessors.processResponse(response)

		} catch (Err err) {

			try {
				response := errProcessors.processErr(err)				
				responseProcessors.processResponse(response)

			} catch (Err doubleErr) {
				// the backup plan for when the err handler errs!
				log.err("ERROR in the ERR HANDLER!!!", doubleErr)
				log.err("  - Original Err", err)
				
				if (!webRes.isCommitted)
					webRes.sendErr(500, err.msg)
			}
			
		} finally {
			httpResponse.out.close
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
