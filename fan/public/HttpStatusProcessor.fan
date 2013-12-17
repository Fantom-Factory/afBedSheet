
** Implement to define a 'HttpStatusProcessor'. Contribute it to the 'HttpStatusProcessors' service. 
const mixin HttpStatusProcessor {
	
	** Process the given `HttpStatus`. Return 'true' if request processing is complete or another 
	** response obj to continue processing. 
	abstract Obj process(HttpStatus httpStatus)
	
}
