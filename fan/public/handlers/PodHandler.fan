
** A Request Handler that maps uris to pod file resources. 
**
** pre>
** @Contribute { serviceType=Routes# }
** static Void contributeRoutes(OrderedConfig conf) {
**   ...
**   conf.add(Route(`/pod/***`, PodHandler#service))
**   ...
** }
** <pre
** 
** Now a request to '/pod/icons/x256/flux.png' should return just that! 
const class PodHandler {

	** Returns `File` pod resource as mapped from the given uri.
	** Throws a `HttpStatusErr` 404 if not found.
	File service(Uri remainingUri := ``) {
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
