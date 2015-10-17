
internal const class HttpOutStreamSafeBuilder : DelegateChainBuilder {
	override OutStream build(Obj delegate) {
		SafeOutStream(delegate)
	}
}
