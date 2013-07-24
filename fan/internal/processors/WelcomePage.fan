using afIoc::Inject
using web::WebOutStream

internal const class WelcomePage {
	
	@Inject private const BedSheetPage 	bedSheetPage
	
	internal new make(|This|in) { in(this) }
	
	Text service() {

		title	:= "BedSheet ${typeof.pod.version}"
		buf 	:= StrBuf()
		out 	:= WebOutStream(buf.out)
		
		out.h1.w("Welcome to BedSheet ${typeof.pod.version}!").h1End
		out.p.w("Something fresh and clean to lay your web app on!").pEnd
		out.p.w("BedSheet is a Fantom framework for delivering web applications.").pEnd
		out.p.w("Full API & fandocs are available on the ")
			 .a(`http://repo.status302.com/doc/afBedSheet/#overview`).w("status302 repository").aEnd
			 .w(".").pEnd
		out.p.w("&nbsp;").pEnd
		out.p.w("To disable this welcome page, contribute a Route in your App Module:").pEnd
		out.code.w("""@Contribute
		              static Void contributeRoutes(OrderedConfig conf) {
		                conf.add(Route(`/hello`, HelloPage#hello))
		              }
		              """).codeEnd

		return bedSheetPage.render(title, buf.toStr)
	}	
}
