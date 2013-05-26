
const class ErrHandlerSource {
	private const Type:ErrHandler errHandlers
	
	new make(Type:ErrHandler errHandlers) {
		this.errHandlers = errHandlers
	}
	
	// TODO: use cached adaprter pattern - see ModuleImpl.serviceDefsByType
	internal ErrHandler getErrHandler(Err err) {
		errHandlers.find |handler, type| {
			err.typeof.fits(type)
        }
		// TODO: throw better Err if not found
	}
	
}
