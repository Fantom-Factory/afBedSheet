
** A response processor for `HttpStatus` objects. Configure 'HttpStatusProcessors' for specific 
** http status codes by contributing to `HttpStatusProcessors`. 
const mixin HttpStatusProcessor {
	
	** Process the given `HttpStatus`. Return 'true' if request processing is complete or another 
	** response obj to continue processing. 
	abstract Obj process(HttpStatus httpStatus)
	
}
