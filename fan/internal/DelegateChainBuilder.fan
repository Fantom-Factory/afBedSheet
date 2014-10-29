
** Used to create a chain of builders for `HttpRequest`, `HttpResponse` and 'HttpOutStream'.
@NoDoc 
const mixin DelegateChainBuilder {
	abstract Obj build(Obj delegate) 
}