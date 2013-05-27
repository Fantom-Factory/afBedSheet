
internal const class TextPage {
	
	Obj plain() {
		TextResult.fromPlain("This is plain text")
	}

	Obj html() {
		TextResult.fromHtml("This is html text <honest!/>")
	}

	Obj xml() {
		TextResult.fromXml("This is xml text <honest!/>")
	}
	
}
