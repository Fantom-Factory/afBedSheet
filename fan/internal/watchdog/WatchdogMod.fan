using concurrent::Actor
using concurrent::AtomicBool
using web::WebClient
using web::WebMod

internal const class WatchdogMod : WebMod {
	private const static Log log := Utils.log

	private const AppRestarter	appRestarter
	
	new make(BedSheetBuilder bob, Int appPort) {
		appRestarter = AppRestarter(bob, appPort)
	}

	override Void onStart() {
		appRestarter.startApp
	}

	override Void onStop() {
		appRestarter.startApp
	}
	
	override Void onService() {

		if (req.modRel == BsConstants.pingUrl) {
			res.headers["Content-Type"] = MimeType("text/plain").toStr
			res.out.print("OK").flush.close
			return
		}

		if (req.modRel == BsConstants.killUrl) {
			res.headers["Content-Type"] = MimeType("text/plain").toStr
			res.out.print("OK").flush.close
			appRestarter.stopApp
			return
		}
	
		if (req.modRel == BsConstants.restartUrl) {
			res.headers["Content-Type"] = MimeType("text/plain").toStr
			res.out.print("OK").flush.close
			appRestarter.restartApp
			return
		}
		
		res.sendErr(404)
	}
}
