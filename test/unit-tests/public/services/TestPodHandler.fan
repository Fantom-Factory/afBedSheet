using afIoc
using afIocEnv
using afBeanUtils

internal class TestPodHandler : BsTest {
	
	Void testUrlPathOnly() {
		verifyBsErrMsg(BsErrMsgs.urlMustBePathOnly(`http://wotever.com`, `/pod/`)) {
			podHandler(`http://wotever.com`)
		}
	}

	Void testUrlNotStartWithSlash() {
		verifyBsErrMsg(BsErrMsgs.urlMustStartWithSlash(`wotever/`, `/pod/`)) {
			podHandler(`wotever/`)
		}
	}

	Void testUrlNotEndWithSlash() {
		verifyBsErrMsg(BsErrMsgs.urlMustEndWithSlash(`/wotever`, `/pod/`)) {
			podHandler(`/wotever`)
		}
	}

	// ---- fromLocalUrl() ----

	Void testLocalUrlIsPathOnly() {
		verifyErrMsg(ArgErr#, BsErrMsgs.urlMustBePathOnly(`http://myStyles.css`, `/pod/icons/x256/flux.png`)) {
			podHandler.fromLocalUrl(`http://myStyles.css`)
		}
		verifyErrMsg(ArgErr#, BsErrMsgs.urlMustBePathOnly(`//myStyles.css`, `/pod/icons/x256/flux.png`)) {
			podHandler.fromLocalUrl(`//myStyles.css`)
		}
	}

	Void testLocalUrlStartsWithSlash() {
		verifyErrMsg(ArgErr#, BsErrMsgs.urlMustStartWithSlash(`css/myStyles.css`, `/pod/icons/x256/flux.png`)) {
			podHandler.fromLocalUrl(`css/myStyles.css`)
		}
	}

	Void testLocalUrlMustBeMapped() {
		verifyErrMsg(ArgErr#, BsErrMsgs.podHandler_urlNotMapped(`/css/myStyles.css`, `/pod/`)) {
			podHandler.fromLocalUrl(`/css/myStyles.css`)
		}
	}

	// ---- fromPodResource() ----
	
	Void testPodUrlHasFanScheme() {
		verifyErrMsg(ArgErr#, BsErrMsgs.podHandler_urlNotFanScheme(`/css/myStyles.css`)) {
			podHandler.fromPodResource(`/css/myStyles.css`)
		}
	}

	Void testPodUrlResolves() {
		verifyErrMsg(ArgErr#, BsErrMsgs.podHandler_urlDoesNotResolve(`fan:/css/myStyles.css`)) {
			podHandler.fromPodResource(`fan:/css/myStyles.css`)
		}
	}

	Void testWhitelistFilter() {
		// sad case
		verifyErrMsg(ArgNotFoundErr#, BsErrMsgs.podHandler_notInWhitelist("fan://icons/x256/flux.png")) {
			podHandler(`/`, "^.*\\.fan\$").fromPodResource(`fan://icons/x256/flux.png`)
		}

		// happy case!
		podHandler(`/`, ".*\\.png\$").fromPodResource(`fan://icons/x256/flux.png`)

		// happy case!
		podHandler(`/`, "^fan://icons/.*\$").fromPodResource(`fan://icons/x256/flux.png`)
	}

	// ---- Happy Cases ----
	
	Void testFromPodResource() {
		asset := podHandler.fromPodResource(`fan://icons/x256/flux.png`)
		verifyEq(asset->file->uri,	`fan://icons/x256/flux.png`)
		verifyEq(asset.localUrl,	`/pod/icons/x256/flux.png`)
		verifyEq(asset.clientUrl,	`/pod/icons/x256/flux.png`)
	}

	Void testFromLocalUrl() {
		asset := podHandler.fromLocalUrl(`/pod/icons/x256/flux.png`)
		verifyEq(asset->file->uri,	`fan://icons/x256/flux.png`)
		verifyEq(asset.localUrl,	`/pod/icons/x256/flux.png`)
		verifyEq(asset.clientUrl,	`/pod/icons/x256/flux.png`)
	}

	private PodHandler podHandler(Uri url := `/pod/`, Str filter := ".*") {
		reg := RegistryBuilder().addModulesFromPod("afIocEnv").addModulesFromPod("afConcurrent").addModule(AssetCacheModule#).build
		try {
			AssetCacheModule.urlRef.val = url
			return reg.rootScope.build(PodHandler#, [Regex[filter.toRegex]])
		} catch (IocErr err) {
			throw err.cause ?: err
		}
//		bob := BeanFactory(PodHandlerImpl#)
//		bob.add([filter.toRegex])
//		bob.setByName("baseUrl", url)
//		bob.setByName("assetCache", AssetCacheMock())
//		return bob.create
//		(Obj)8
	}
}

