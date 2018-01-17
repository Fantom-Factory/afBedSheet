using afIoc::Inject
using afIoc::Scope

internal const class HttpOutStreamOnCommitBuilder : DelegateChainBuilder {
	@Inject	private const Scope 		scope

	new make(|This|in) { in(this) }

	override OutStream build(Obj delegate) {
		scope.registry.activeScope.build(OnCommitOutStream#, [delegate])
	}
}
