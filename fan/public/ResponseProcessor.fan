
** Implement to define a 'ResponseProcessor'. Contribute it to the 'ResponseProcessors' service.
**  
** 'ResponseProcessors' are responsible for processing the return values from request handlers. Often this involves 
** sending content to the client.
const mixin ResponseProcessor {
	
	** Return 'true' if a response has been sent to the client and all processing has finished. 
	** Else return a response  object for further processing, example, `Text`. 
	abstract Obj process(Obj response)
		
}
