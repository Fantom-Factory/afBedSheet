
** Responsible for processing Errs thrown from request handler methods and sending err pages to the client. 
const mixin ErrProcessor {
	
	** Returns a response obj for further processing (such as a `TextResponse`) or 'true' if no 
	** more request processing is required.
	abstract Obj process(Err err)
	
}
