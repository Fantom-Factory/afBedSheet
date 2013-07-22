using afIoc::Inject
using afIoc::Registry

internal const class HttpOutStreamBuffBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry
	@Inject	private const HttpResponse 		response

	new make(|This|in) { in(this) } 
	
	override OutStream build(Obj delegate) {
		doBuff	:= !response.isBufferingDisabled
		return	doBuff ? registry.autobuild(BufferedOutStream#, [delegate]) : delegate 
	}
}
