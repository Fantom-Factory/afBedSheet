
internal const class TextPage {
	
	Obj plain() {
		TextResponse.fromPlain("This is plain text")
	}

	Obj html() {
		TextResponse.fromHtml("This is html text <honest!/>")
	}

	Obj xml() {
		TextResponse.fromXml("This is xml text <honest!/>")
	}
	
}
