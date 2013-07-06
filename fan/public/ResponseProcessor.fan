
** Responsible for processing request handler return values and sending content to the client.
const mixin ResponseProcessor {
	
	abstract Obj? process(Obj response)
		
}
