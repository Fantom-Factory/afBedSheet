using afIoc3

@NoDoc	// Don't overwhelm the masses
const class RequestLoggers : Middleware {
	
	@Inject
	private const Log				log
	internal const RequestLogger[]	requestLoggers
	
	new make(RequestLogger[] requestLoggers, |This|in) {
		in(this)
		this.requestLoggers = requestLoggers
	}
	
	override Void service(MiddlewarePipeline pipeline) {
		requestLoggers.each { 
			try it.logIncoming
			catch (Err err)
				log.err("Error in ${it.typeof.qname}.logIncoming() - ignoring...", err)
		}
		
		pipeline.service

		requestLoggers.each { 
			try it.logOutgoing
			catch (Err err)
				log.err("Error in ${it.typeof.qname}.logOutgoing() - ignoring...", err)				
		}
	}
}

@NoDoc	// Don't overwhelm the masses
const class BasicRequestLogger : RequestLogger {
	@Inject private const HttpRequest		httpRequest
	@Inject private const HttpResponse		httpResponse
	@Inject private const |->RequestState|	reqState
	@Inject private const Log				log
	
	new make(|This|in) { in(this) }
	
	// FIXME: configure loggin to be INFO by default
	override Void logOutgoing() {
		if (log.isDebug) {
			// attempt to keep the standard debug line at 120 chars (120 isn't special, it just seems to be a manageable width)
			timeTaken := Duration.now.minus(reqState().startTime)
			len := 56 - (httpRequest.httpMethod.size.max(4) - 4)
			url := "${httpRequest.url.encode} ".padr(len, '-') + "->"
			msg := "${httpRequest.httpMethod.justl(4)} ${url} ${httpResponse.statusCode} (in ${timeTaken.toLocale.justr(4)})"
			log.debug(msg)
		}
	}
}
