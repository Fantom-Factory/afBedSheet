
** Responsible for processing request handler return values and sending content to the client.
const mixin ResponseProcessor {
	
	** Return 'true' if a response has been sent to the client and all processing has finished. 
	** Else return a response  object for further processing, example, `TextResponse`. 
	abstract Obj process(Obj response)
		
}
