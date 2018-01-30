using afIoc::Inject
using web::WebOutStream

** (Service) - Renders the standard 'BedSheet' web pages.
@NoDoc	// Advanced use only
const mixin BedSheetPages {

	** Renders the 'BedSheet' status page, such as the 404 page.
	abstract Text? renderHttpStatus(HttpStatus httpStatus, Bool verbose)

	** Renders the 'BedSheet' Err page. If 'verbose' is 'false' a very minimal page is rendered, otherwise the standard
	** detail BedSheet Err page is rendered.
	** 
	** > **ALIEN-AID:** To ensure you see the verbose Err page, start 'BedSheet' with the '-env dev' option or set the 
	** environment variable 'env' to 'dev'.   
	abstract Text? renderErr(Err err, Bool verbose)
	
	** Renders the 'BedSheet' welcome page. 
	** Usually shown in place of a 404 if no [Routes]`Route` have been contributed to the `Routes` service. 
	abstract Text? renderWelcome(HttpStatus httpStatus)
}

internal const class BedSheetPagesImpl : BedSheetPages {

	@Inject	private const HttpRequest				httpRequest
	@Inject	private const HttpResponse				httpResponse
	@Inject	private const |->ErrPrinterHtml|		errPrinterHtml
	@Inject	private const |->ErrPrinterStr|			errPrinterStr
	@Inject	private const |->NotFoundPrinterHtml| 	notFoundPrinterHtml

	new make(|This|in) { in(this) }

	override Text? renderHttpStatus(HttpStatus httpStatus, Bool verbose) {
		title	:= "${httpStatus.code} - " + HttpResponse.statusMsg[httpStatus.code]
		// if the msg is html, leave it as is
		msg		:= httpStatus.msg.startsWith("<p>") ? httpStatus.msg : "<p><b>${httpStatus.msg}</b></p>\n"
		xhtml	:= (verbose && httpStatus.code == 404) ? msg + notFoundPrinterHtml().toHtml : msg
		str		:= httpStatus.toStr
		return render(title, xhtml, str)
	}	

	override Text? renderErr(Err err, Bool verbose) {
		title	:= "500 - " + HttpResponse.statusMsg[500]
		xhtml	:= verbose ? errPrinterHtml().errToHtml(err) : "<p><b>${err.msg}</b></p>\n"
		str		:= verbose ? errPrinterStr() .errToStr (err) : "${err.msg}\n"
		return render(title, xhtml, str, BedSheetLogo.skull)
	}
	
	override Text? renderWelcome(HttpStatus httpStatus) {
		title	:= "BedSheet ${typeof.pod.version}"
		xhtml	:= typeof.pod.file(`/res/web/welcomePage.html`).readAllStr
					.replace("{{{ bedSheetVersion }}}", typeof.pod.version.toStr)
		str		:= httpStatus.toStr
					.replace("{{{ bedSheetVersion }}}", typeof.pod.version.toStr)
		return render(title, xhtml, str)
	}
	
	private Text? render(Str title, Str xhtmlContent, Str strContent, BedSheetLogo logo := BedSheetLogo.alienHead) {
		alienHeadSvg	:= typeof.pod.file(logo.svgUri).readAllStr
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		bedSheetXhtml	:= typeof.pod.file(`/res/web/bedSheet.html`).readAllStr
		version			:= typeof.pod.version.toStr
		xhtml			:= bedSheetXhtml		// Gotta go old skool now moustache has been moved out from BedSheet core 
							.replace("{{{ title }}}", title)
							.replace("{{{ bedSheetCss }}}", bedSheetCss)
							.replace("{{{ alienHeadSvg }}}", alienHeadSvg)
							.replace("{{{ content }}}", xhtmlContent)
							.replace("{{{ version }}}", version)

		csp := httpResponse.headers.contentSecurityPolicy
		if (csp != null) {
			styleSrc := csp.get("style-src", "")
			if (!styleSrc.split.contains("'unsafe-inline'")) {
				if (!styleSrc.isEmpty) styleSrc += " "
				csp["style-src"] = styleSrc + "'sha256-" + bedSheetCss.toBuf.toDigest("SHA-256").toBase64 + "'"
				httpResponse.headers.contentSecurityPolicy = csp
			}
	
			imageSrc := csp.get("img-src", "")
			if (!imageSrc.split.contains("data:")) {
				if (!imageSrc.isEmpty) imageSrc += " "
				csp["img-src"] = imageSrc + "data:"
				httpResponse.headers.contentSecurityPolicy = csp
			}
		}

		return toText(xhtml, strContent)
	}
	
	private Text? toText(Str xhtml, Str str) {
		retType	:= "plain" as Str	// the default if no accept header is sent

		accept  := httpRequest.headers.accept
		if (accept != null) {
			accMap := [
				["html",  accept.get("text/html")],
				["plain", accept.get("text/plain")],
				["xhtml", accept.get("application/xhtml+xml")]
			].sortr |a1, a2| { a1[1] <=> a2[1] }
				
			accepts := accMap.first
			if (accepts.last == 0f)
				retType = null
			else
				retType = accepts.first
		}
		
		if (retType == "html")
			return Text.fromHtml(StrBuf().add(xhtml).replaceRange(0..<60, "<!DOCTYPE html>\n<html>\n").toStr)
		if (retType == "plain")
			return Text.fromPlain(str)
		if (retType == "xhtml")
			return Text.fromXhtml(xhtml)
		
		// client doesn't want anything we have... :(
		return null
	}	
}

internal enum class BedSheetLogo {
	alienHead(`/res/web/bedSheetLogo.html`),
	skull(`/res/web/skull.svg`);
	
	const Uri svgUri
	private new make(Uri svgUri) {
		this. svgUri = svgUri
	}
}