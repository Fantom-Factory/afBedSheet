using afIoc::Inject

** (Service) - 
internal const class BedSheetPage {
 
	new make(|This|in) { in(this) }

	Text render(Str title, Str content, BedSheetLogo logo := BedSheetLogo.alienHead) {
		alienHeadSvg	:= typeof.pod.file(logo.svgUri).readAllStr
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		bedSheetHtml	:= typeof.pod.file(`/res/web/bedSheet.html`).readAllStr
		version			:= typeof.pod.version.toStr
		html			:= bedSheetHtml		// Gotta go old skool now that moustache has been moved out 
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