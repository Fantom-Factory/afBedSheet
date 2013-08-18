using afIoc::Inject

internal const class BedSheetPage {
	
	new make(|This|in) { in(this) }

	Text render(Str title, Str content) {
		bedSheetCss		:= typeof.pod.file(`/res/web/bedSheet.css`).readAllStr
		alienHeadSvg	:= typeof.pod.file(`/res/web/alienHead.svg`).readAllStr
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
