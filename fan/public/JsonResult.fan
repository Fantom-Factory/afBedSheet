using util::JsonOutStream

** Json result?
class JsonResult {
	
	private Obj jsonObj
	
	new make(Obj jsonObj) {
		this.jsonObj = jsonObj
	}
	
	Str toJsonStr() {
		JsonOutStream.writeJsonToStr(jsonObj)
	}
}
