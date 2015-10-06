using afIoc

internal const class HttpOutStreamBuilder {
	@Inject 
	private const |->Scope|				 scope
	private const DelegateChainBuilder[] builders
	
	new make(DelegateChainBuilder[] builders, |This|in) {
		in(this)
		this.builders = builders
	}
	
	OutStream build() {
		out := scope().build(WebResOutProxy#)
		return builders.reduce(out) |Obj delegate, DelegateChainBuilder builder -> Obj| { 		
			return builder.build(delegate)
		}
	}
}
