using afIoc::Inject
using afIoc::Scope
using afIocConfig::Config
using afBeanUtils::ArgNotFoundErr

// FIXME suggest proper fix for JS Source Maps @ http://fantom.org/forum/topic/2531
** (Service) - 
** Serves up Fantom source files for Javascript Source Maps. 
@NoDoc
const mixin SrcMapHandler : ClientAssetProducer {
	
	** The local URL under which Fantom source is served.
	** 
	** Set by `BedSheetConfigIds.srcMapHandlerBaseUrl`, defaults to '/dev/'.
	abstract Uri? baseUrl()
}

internal const class SrcMapHandlerImpl : SrcMapHandler {

	@Config { id="afBedSheet.srcMapHandler.baseUrl" }
	@Inject override const Uri?					baseUrl	:= `/dev/`
	@Inject	private const |->ClientAssetCache|	assetCache
	@Inject	private const Scope					scope
	
	new make(|This|? in) {

		in?.call(this)
		
		if (baseUrl == null)
			return

		if (!baseUrl.isPathOnly)
			throw BedSheetErr(BsErrMsgs.urlMustBePathOnly(baseUrl, `/dev/`))
		if (!baseUrl.isPathAbs)
			throw BedSheetErr(BsErrMsgs.urlMustStartWithSlash(baseUrl, `/dev/`))
		if (!baseUrl.isDir)
			throw BedSheetErr(BsErrMsgs.urlMustEndWithSlash(baseUrl, `/dev/`))
	}

	override ClientAsset? produceAsset(Uri localUrl) {
		_fromLocalUrl(localUrl, false, false)
	}

	ClientAsset? _fromLocalUrl(Uri localUrl, Bool checked, Bool cache) {
		if (baseUrl == null)
			if (checked) throw Err(BsErrMsgs.srcMapHandler_disabled)
			else return null

		Utils.validateLocalUrl(localUrl, `/pod/icons/x256/flux.png`)
		if (!localUrl.toStr.startsWith(baseUrl.toStr))
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotMapped(localUrl, baseUrl))
			else return null

		remainingUrl := localUrl.relTo(baseUrl)

		url := remainingUrl
		if (!url.isDir)
			url = url.parent.plusSlash.plusName("src").plusSlash.plusName(url.name)
		return _fromPodResource(`fan://${url}`, checked, true)
	}
	
	ClientAsset? _fromPodResource(Uri podUrl, Bool checked, Bool cache) {
		if (baseUrl == null)
			if (checked) throw Err(BsErrMsgs.srcMapHandler_disabled)
			else return null
 
		if (podUrl.scheme != "fan")
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotFanScheme(podUrl))
			else return null

		resource := (Obj?) null
		try resource = podUrl.get
		catch 
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlDoesNotResolve(podUrl))
			else return null

		if (resource isnot File)	// WTF!?
			if (checked) throw ArgErr(BsErrMsgs.podHandler_urlNotFile(podUrl, resource))
			else return null

		file		:= (File) resource
		host		:= file.uri.host.toUri.plusSlash
		path		:= file.uri.pathOnly.relTo(`/`)
		localUrl	:= baseUrl + host + path

		makeFunc := |Uri key->ClientAsset?| {
			if (!file.exists)
				if (checked) throw ArgErr(BsErrMsgs.fileNotFound(file))
				else return null
			
			return scope.build(FileAsset#, [localUrl, file])
		}
		
		return cache ? assetCache().getAndUpdateOrMake(localUrl, makeFunc) : makeFunc(localUrl) 
	}	
}
