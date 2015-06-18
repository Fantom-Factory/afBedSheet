
** (Service) - Contribute your `ResponseProcessor` implementations to this.
** 
** @uses a Configuration of 'Type:ResponseProcessor'
@NoDoc	// Don't overwhelm the masses!
const mixin ResponseProcessors {

	** Recursively processes the response object until 'true' or 'false' is returned
	@NoDoc // not for public use
	abstract Bool processResponse(Obj response)

}

internal const class ResponseProcessorsImpl : ResponseProcessors {

	private const CachingTypeLookup processorLookup

	internal new make(Type:ResponseProcessor responseProcessors) {
		processorLookup = CachingTypeLookup(responseProcessors)
	}

	override Bool processResponse(Obj response) {
		while (!response.typeof.fits(Bool#)) {
			try {
				response = get(response.typeof).process(response)
				
			// We handle ReProcessErrs as close to the source as possible as not to bounce back through any 
			// Middleware
			} catch (ReProcessErr rpe) {
				// re-process any, um, ReProcessErrs!
				response = rpe.responseObj
				
			} catch (Err err) {
				// unwrap looking for a ReProcessErr 'cos some frameworks, like efan, may have wrapped it
				cause := (Err?) err
				while (cause != null && cause isnot ReProcessErr)
					cause = cause.cause			
				if (cause isnot ReProcessErr)
					throw err
				return ((ReProcessErr) cause).responseObj
			}
		}
		
		// false is fine, it means it wasn't handled, fall through to the next route / middleware
		return response
	}	

	private ResponseProcessor get(Type responseType) {
		// see http://stackoverflow.com/questions/25262348/why-afbedsheet-dont-see-my-types
		processorLookup.findParent(responseType, false) ?: throw UnknownResponseObjectErr("Could not find a ResponseProcessor to handle an instance of ${responseType.qname}", processorLookup.types)
	}
}
