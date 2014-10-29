using afIoc::Inject
using web::WebOutStream
using web::WebRes

** (Service) - Renders the standard 'BedSheet' web pages.
const mixin BedSheetPages {

	** Renders the 'BedSheet' status page, such as the 404 page.
	abstract Text renderHttpStatus(HttpStatus httpStatus, Bool verbose)

	** Renders the 'BedSheet' Err page. If 'verbose' is 'false' a very minimal page is rendered, otherwise the standard
	** detail BedSheet Err page is rendered.
	** 
	** > **ALIEN-AID:** To ensure you see the verbose Err page, start 'BedSheet' with the '-env dev' option or set the 
	** environment variable 'env' to 'dev'.   
	abstract Text renderErr(Err err, Bool verbose)
	
	** Renders the 'BedSheet' welcome page. 
	** Usually shown in place of a 404 if no [Routes]`Route` have been contributed to the `Routes` service. 
	abstract Text renderWelcome()
}

internal const class BedSheetPagesImpl : BedSheetPages {

	@Inject	private const HttpRequest			request
	@Inject	private const ErrPrinterHtml 		errPrinterHtml
	@Inject	private const NotFoundPrinterHtml 	notFoundPrinterHtml

	new make(|This|in) { in(this) }

	override Text renderHttpStatus(HttpStatus httpStatus, Bool verbose) {
		title	:= "${httpStatus.code} - " + WebRes.statusMsg[httpStatus.code]
		// if the msg is html, leave it as is
		msg		:= httpStatus.msg.startsWith("<p>") ? httpStatus.msg : "<p><b>${httpStatus.msg}</b></p>\n"
		content	:= (verbose && httpStatus.code == 404) ? msg + notFoundPrinterHtml.toHtml : msg
		return render(title, content)
	}	

	override Text renderErr(Err err, Bool verbose) {
		title	:= "500 - " + WebRes.statusMsg[500]
		content	:= verbose ? errPrinterHtml.errToHtml(err) : "<p><b>${err.msg}</b></p>\n"
		return render(title, content, BedSheetLogo.skull)
	}
	
	override Text renderWelcome() {
		title	:= "BedSheet ${typeof.pod.version}"
		content	:= typeof.pod.file(`/res/web/welcomePage.html`).readAllStr
		content	 = content.replace("{{{ bedSheetVersion }}}", typeof.pod.version.toStr)
		return render(title, content)
	}	
	
	private Text render(Str title, Str content, BedSheetLogo logo := BedSheetLogo.alienHead) {
		alienHeadSvg	:= typeof.pod.file(logo.svgUri).readAllStr
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		bedSheetXhtml	:= typeof.pod.file(`/res/web/bedSheet.html`).readAllStr
		version			:= typeof.pod.version.toStr
		xhtml			:= bedSheetXhtml		// Gotta go old skool now moustache has been moved out from BedSheet core 
							.replace("{{{ title }}}", title)
							.replace("{{{ bedSheetCss }}}", bedSheetCss)
							.replace("{{{ alienHeadSvg }}}", alienHeadSvg)
							.replace("{{{ content }}}", content)
							.replace("{{{ version }}}", version)

		return Text.fromXhtml(xhtml)
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