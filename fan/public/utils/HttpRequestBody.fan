using web::WebReq
using util::JsonInStream

** Convenience methods for accessing the request body.
class HttpRequestBody {
	private WebReq webReq
	
	internal new make(WebReq webReq) {
		this.webReq = webReq
	}
	
	** Returns the request body as an 'InStream'. See `web::WebUtil.makeContentInStream` to check under 
	** which conditions request content is available. If request content is not available, then 
	** return 'null'.
	**
	** If the client specified the "Expect: 100-continue" header, then the first access of the 
	** request input stream will automatically send the client a '100 Continue' response.
	**
	** @see `web::WebReq.in`
	InStream? in() {
		try return webReq.in
		catch (Err err) {
			if (err.msg.contains("Attempt to access WebReq.in with no content"))
				return null
			throw err
		}
	}
	
	** Returns the request body as a 'Buf'. 
	** Returns 'null' if there is no request content.
	once Buf? buf() {
		in?.readAllBuf
	}
	
	** Returns the request body as a 'Str'. 
	** Returns 'null' if there is no request content.
	once Str? str() {
		try return buf?.seek(0)?.readAllStr
		catch (Err err) throw HttpStatusErr(400, "Invalid Str Data", err)
	}
	
	** Returns the request body as a JSON Obj. Parsing is done with `util::JsonInStream`
	** If the JSON is invalid, a 'HttpStatusErr' is thrown with a status code of '400 - Bad Request'.
	** Returns 'null' if there is no request content.
	once Obj? jsonObj() {
		if (buf == null) return null
		try return JsonInStream(buf.seek(0).in).readJson
		catch (Err err) throw HttpStatusErr(400, "Invalid JSON Data", err)
	}
	
	** Returns the request body as a JSON Map. 
	** Convenience for '([Str:Obj?]?) body.jsonObj()'.
	once [Str:Obj?]? jsonMap() {
		jsonObj
	}

	** Get the request body as a form of key / value pairs. The form is parsed using `sys::Uri.decodeQuery`.
	** 
	** If the form data is invalid, a 'HttpStatusErr' is thrown with a status code of '400 - Bad Request'.
	once [Str:Str]? form() {
		if (str == null) return null
		try return Uri.decodeQuery(str)
		catch (Err err) throw HttpStatusErr(400, "Invalid Form Data", err)
	}

	@NoDoc
	override Str toStr() {
		try return str ?: "null"
		catch return buf?.toStr ?: "null"
	}
}
