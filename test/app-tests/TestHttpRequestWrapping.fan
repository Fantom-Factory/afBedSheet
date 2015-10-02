using web::WebClient
using afIoc3

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

internal const class T_HttpReqWrapMod1 {
	@Contribute { serviceType=Routes# }
	static Void contributeRoutes(Configuration conf) {
		conf.add(Route(`/httpReq1`,	T_PageHandler#httpReq1))
		conf.add(Route(`/httpReq2`,	T_PageHandler#httpReq2))
	}
	
	@Contribute { serviceType=HttpRequest# }
	static Void contributeHttpRequest(Configuration conf) {
		conf["HttpRequestWrapperBuilder"] = conf.build(T_HttpRequestWrapperBuilder#)
	}
}

internal const class T_HttpRequestWrapperBuilder : DelegateChainBuilder {
	@Inject	private const Registry 			registry

	new make(|This|in) { in(this) } 
	
	override HttpRequest build(Obj delegate) {
		return T_MyHttpRequest((HttpRequest) delegate) 
	}
}


internal const class T_MyHttpRequest : HttpRequestWrapper {
	new make(HttpRequest req) : super(req) { }
	override Uri url() { `/httpReq2`	}
}