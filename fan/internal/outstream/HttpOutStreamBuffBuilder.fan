using afIoc

internal const class HttpOutStreamBuffBuilder : DelegateChainBuilder {
	@Inject	private const Scope 		scope
	@Inject	private const HttpResponse 	response

	new make(|This|in) { in(this) } 
	
	override OutStream build(Obj delegate) {
		doBuff	:= !response.disableBuffering
		return	doBuff ? scope.build(BufferedOutStream#, [delegate]) : delegate 
	}
}
