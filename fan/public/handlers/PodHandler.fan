
** (Service) - A Request Handler that maps URIs to file resources inside pods. 
**
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(Configuration conf) {
**   ...
**   conf.add(Route(`/pod/***`, PodHandler#service))
**   ...
** }
** <pre
** 
** Now a request to '/pod/icons/x256/flux.png' should return just that! 
const mixin PodHandler {
	
	** Returns a pod resource (as a 'File') as mapped from the given uri.
	** Throws a `HttpStatusErr` 404 if not found.
	abstract File service(Uri remainingUri)

}

internal const class PodHandlerImpl : PodHandler {

	override File service(Uri remainingUri) {
		// must have at least 3 path segments
		path := remainingUri.path
		if (path.size < 2)
			throw HttpStatusErr(404, "File not found: $remainingUri")

		// lookup pod
		pod := Pod.find(path[0], false)
		if (pod == null)
			throw HttpStatusErr(404, "Pod not found: ${path[1]}")

		// lookup file
		file := pod.file(`/` + remainingUri[1..-1], false)
		if (file == null)
			throw HttpStatusErr(404, "Resource not found: ${pod.name}::/${remainingUri[1..-1]}")

		return file
	}
}
