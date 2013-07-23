using web::WebClient
using afIoc

internal class TestHttpRequestWrapping : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testWrappedHttpReqReRoutes() {
		iocModules = super.iocModules.add(T_HttpReqWrapMod1#)
		super.setup
		
		page := getAsStr(`/httpReq1`)
		verifyEq(page, "On page 2")
	}
}

internal class T_HttpReqWrapMod1 {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(OrderedConfig conf) {
		conf.add(Route(`/httpReq1`,				T_PageHandler#httpReq1))
		conf.add(Route(`/httpReq2`,				T_PageHandler#httpReq2))
	}
	
	@Contribute { serviceId="HttpRequest" }
	static Void contributeHttpRequest(OrderedConfig conf) {
		conf.addOrdered("HttpRequestWrapperBuilder", conf.autobuild(T_HttpRequestWrapperBuilder#))
	}
}

internal const class T_HttpRequestWrapperBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry

	new make(|This|in) { in(this) } 
	
	override HttpRequest build(Obj delegate) {
		return T_MyHttpRequest((HttpRequest) delegate) 
	}
}


internal const class T_MyHttpRequest : HttpRequestDelegate {
	new make(HttpRequest req) : super(req) { }
	override Uri modRel() { `/httpReq2`	}
}