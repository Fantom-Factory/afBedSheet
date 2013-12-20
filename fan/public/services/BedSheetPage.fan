using afIoc::Inject
using web::WebOutStream
using web::WebRes

** (Service) - Renders the standard 'BedSheet' web pages.
const mixin BedSheetPage {

	** Renders the 'BedSheet' status page, such as the 404 page.
	abstract Text renderHttpStatus(HttpStatus httpStatus)

	** Renders the 'BedSheet' Err page. If 'verbose' is 'false' a very minimal page is rendered, otherwise the standard
	** detail BedSheet Err page is rendered.
	** 
	** > **ALIEN-AID:** To ensure you see the verbose Err page, start 'BedSheet' with the '-env dev' option or set the 
	** environment variable 'env' to 'dev'.   
	abstract Text renderErr(Err err, Bool verbose)
	
	** Renders the 'BedSheet' welcome page. 
	** Usually shown if no [Routes]`Route` have been contributed to the `Routes` service. 
	abstract Text renderWelcomePage()
}

internal const class BedSheetPageImpl : BedSheetPage {

	@Inject	private const ErrPrinterHtml 	errPrinterHtml

	new make(|This|in) { in(this) }

	override Text renderHttpStatus(HttpStatus httpStatus) {
		title	:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		// if the msg is html, leave it as is
		content	:= httpStatus.msg.startsWith("<p>") ? httpStatus.msg : "<p><b>${httpStatus.msg}</b></p>"
		return render(title, content)
	}	

	override Text renderErr(Err err, Bool verbose) {
		title	:= "500 - " + WebRes.statusMsg[500]
		content	:= verbose ? errPrinterHtml.errToHtml(err) : "<p><b>${err.msg}</b></p>"
		return render(title, content, BedSheetLogo.skull)
	}
	
	override Text renderWelcomePage() {
		title	:= "BedSheet ${typeof.pod.version}"
		buf 	:= StrBuf()
		out 	:= WebOutStream(buf.out)

		// move html to text file..?
		out.h1.w("Welcome to BedSheet ${typeof.pod.version}!").h1End
		out.p.w("Something fresh and clean to lay your web app on!").pEnd
		out.p.w("BedSheet is a Fantom framework for delivering web applications.").pEnd
		out.p.w("Full API & fandocs are available on the ")
			 .a(`http://repo.status302.com/doc/afBedSheet/#overview`).w("status302 repository").aEnd
			 .w(".").pEnd
		out.p.w("&nbsp;").pEnd
		out.p.w("To disable this welcome page, contribute a Route in your App Module:").pEnd
		out.code.w("""@Contribute { serviceType=Routes# }
		              static Void contributeRoutes(OrderedConfig conf) {
		                conf.add(Route(`/hello`, Text.fromPlain("Hello!")))
		              }
		              """).codeEnd
		out.p.w("Or ensure BedSheet can find your AppModule. Do this by adding meta to your project's build.fan:").pEnd
		out.code.w("""meta = [ ...
		                       "afIoc.module" : "myPod::AppModule",
		                       ...
		                     ]
		              """).codeEnd

		return render(title, buf.toStr)
	}	
	
	private Text render(Str title, Str content, BedSheetLogo logo := BedSheetLogo.alienHead) {
		alienHeadSvg	:= typeof.pod.file(logo.svgUri).readAllStr
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.html`).readAllStr
		version			:= typeof.pod.version.toStr
		html			:= bedSheetHtml		// Gotta go old skool now moustache has been moved out from BedSheet core 
							.replace("{{{ title }}}", title)
							.replace("{{{ bedSheetCss }}}", bedSheetCss)
							.replace("{{{ alienHeadSvg }}}", alienHeadSvg)
							.replace("{{{ content }}}", content)
							.replace("{{{ version }}}", version)

		return Text.fromHtml(html)
	}
}

internal enum class BedSheetLogo {
	alienHead(`/res/web/alienHead.svg`),
	skull(`/res/web/skull.svg`);
	
	const Uri svgUri
	private new make(Uri svgUri) {
		this. svgUri = svgUri
	}
}