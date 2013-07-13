
const class Redirect {
	
	** The URI to redirect to
	const Uri uri
	
	internal const RedirectType type
	
	private new make(Uri redirectTo, RedirectType type) {
		this.uri = redirectTo
		this.type = type
	}
	
	static new movedPermanently(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.movedPermanently)
	}

	static new movedTemporarily(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.movedTemporarily)
	}

	static new afterPost(Uri redirectTo) {
		Redirect.make(redirectTo, RedirectType.afterPost)
	}
}

** the order is important - see `RedirectResponseProcessor`
internal enum class RedirectType {
	movedPermanently,
	movedTemporarily,
	afterPost;
}