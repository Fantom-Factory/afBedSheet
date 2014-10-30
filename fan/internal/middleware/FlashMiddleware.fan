using afIoc::Inject
using afConcurrent::LocalRef

internal const class FlashMiddleware : Middleware {
	
	@Inject	private const HttpSession	httpSession
	@Inject private const LocalRef		carriedOverRef

	new make(|This|in) { in(this) }
	
	override Void service(MiddlewarePipeline pipeline) {
		carriedOverRef.val = (([Str:Obj?]?) httpSession["afBedSheet.flash"])?.dup
		
		pipeline.service
		
		flashMap	:= (Str:Obj?) (httpSession["afBedSheet.flash"] ?: [:])
		carriedOver	:= (Str:Obj?) (carriedOverRef.val ?: [:])
		
		carriedOver.each |val, key| {
			// remove old key / values that have not changed
			// TODO: this means we can not re-set the same value!
			if (flashMap.containsKey(key) && flashMap[key] == val)
				flashMap.remove(key)
		}

		flashMap.each {
			// test serialisation - would rather do this sooner if we could
			Buf().out.writeObj(it, ["skipErrors":false])
		}
		
		if (flashMap.isEmpty)
			httpSession.remove("afBedSheet.flash")
	}
}
