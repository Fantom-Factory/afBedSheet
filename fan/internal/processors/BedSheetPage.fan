using afIoc::Inject

internal const class BedSheetPage {
	
	@Inject private const MoustacheTemplates 	moustaches
	@Inject	private const HttpResponse 			response
	
	new make(|This|in) { in(this) }
	
	Text render(Str title, Str content) {
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		alienHeadSvg	:= typeof.pod.file(`/res/web/alienHead.svg`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.moustache`)
		version			:= typeof.pod.version.toStr
		html 			:= moustaches.renderFromFile(bedSheetHtml, [
			"title"			: title,
			"bedSheetCss"	: bedSheetCss,
			"alienHeadSvg"	: alienHeadSvg,
			"content"		: content,
			"version"		: version
		])
		
		return Text.fromHtml(html)
	}	
}
