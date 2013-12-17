
** Implement to define an 'ErrProcessor'.
** Contribute it to the `ErrProcessors` service.
** 
** 'ErrProcessors' processes Errs thrown from request handler methods. They generally generate and send err pages to 
** the client. 
const mixin ErrProcessor {
	
	** Returns a response obj for further processing (such as a `Text`) or 'true' if no 
	** more request processing is required.
	abstract Obj process(Err err)
	
}
