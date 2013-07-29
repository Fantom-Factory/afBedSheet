using afIoc::ConcurrentState

** Stores values from one http request to the next. 
** The values stored must be serializable.
const mixin HttpFlash {
	
	@Operator
	abstract Obj? get(Str name)

	** The given value must be serializable.
	@Operator 
	abstract Void set(Str name, Obj? val)
	
	** Internal method - don't come crying to me when I delete it!
	@NoDoc
	abstract Void setReq([Str:Obj?]? req)
	
	** Internal method - don't come crying to me when I delete it!
	@NoDoc
	abstract [Str:Obj?]? getRes()
}

internal const class HttpFlashImpl : HttpFlash {
	private const ConcurrentState 	conState	:= ConcurrentState(HttpFlashState#)

	override Obj? get(Str name) {
		getState |state->Obj?| {
			if (state.res.containsKey(name))
				return state.res.get(name)
			return state.req?.get(name)
		}
	}

	override Void set(Str name, Obj? val) {
		withState |state| {
			state.res[name] = val
		}.get
	}
	
	override Void setReq([Str:Obj?]? req) {
		reqImm := req?.toImmutable
		withState {	it.req = reqImm	} 
	}

	override [Str:Obj?]? getRes() {
		getState { it.res.isEmpty ? null : it.res.toImmutable } 
	}

	private Obj? getState(|HttpFlashState -> Obj?| state) {
		conState.getState(state)
	}	

	private concurrent::Future withState(|HttpFlashState| state) {
		conState.withState(state)
	}	
}

internal class HttpFlashState {
	[Str:Obj?]? req
	[Str:Obj?] 	res	:= [:]
}