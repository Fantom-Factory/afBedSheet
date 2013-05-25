using util::JsonOutStream

class Json {
	
	private Obj jsonObj
	
	new make(Obj jsonObj) {
		this.jsonObj = jsonObj
	}
	
	Str toJsonStr() {
		JsonOutStream.writeJsonToStr(jsonObj)
	}
}
