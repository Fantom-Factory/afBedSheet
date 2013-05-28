
** Responsible for processing Errs thrown from web handler methods and sending err pages to the client. 
const mixin ErrProcessor {
	
	abstract Obj process(Err err)
	
}
