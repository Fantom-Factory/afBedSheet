
** Responsible for processing Errs thrown from web handler methods and sending err pages to the client. 
const mixin ErrProcessor {
	
	** TOOD: I'm not convinced ErrProcessors should return a result to handle...
	abstract Obj process(Err err)
	
}
