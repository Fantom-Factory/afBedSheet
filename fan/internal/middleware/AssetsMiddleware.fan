using afIoc3::Inject

internal const class AssetsMiddleware : Middleware {

	@Inject	private const HttpRequest			httpRequest
	@Inject	private const ClientAssetCache		assetCache
	@Inject private const ResponseProcessors	processors

	new make(|This|in) { in(this) }

	override Void service(MiddlewarePipeline pipeline) {
		if (httpRequest.httpMethod == "GET" || httpRequest.httpMethod == "HEAD") {
			asset := assetCache.getAndUpdateOrProduce(httpRequest.url)
			if (asset != null)
				if (processors.processResponse(asset))
					return
		}
		pipeline.service
	}	
}
