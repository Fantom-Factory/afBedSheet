using concurrent
using afIoc
using afIocEnv
using afBeanUtils

internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyBsErrMsg(BsErrMsgs.fileHandler_notDir(File(`build.fan`))) {
			makeFileHandler( [`/wotever/`:File(`build.fan`)] )
		}
	}

	Void testFilesExist() {
		verifyBsErrMsg(BsErrMsgs.fileHandler_dirNotFound(File(`wotever`))) {
			makeFileHandler( [`/wotever/`:File(`wotever`)] )
		}
	}

	Void testUrlPathOnly() {
		verifyBsErrMsg(BsErrMsgs.fileHandler_urlNotPathOnly(`http://wotever.com`, `/foo/bar/`)) {
			makeFileHandler( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUrlNotStartWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandler_urlMustStartWithSlash(`wotever/`, `/foo/bar/`)) {
			makeFileHandler( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUrlNotEndWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandler_urlMustEndWithSlash(`/wotever`)) {
			makeFileHandler( [`/wotever`:File(`test/`)] )
		}
	}

	// ---- from Client Uri ----

	Void testAssetUrlIsPathOnly() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_urlNotPathOnly(`http://myStyles.css`, `/css/myStyles.css`)) {
			fh.fromLocalUrl(`http://myStyles.css`)
		}
	}

	Void testAssetUrlStartsWithSlash() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_urlMustStartWithSlash(`css/myStyles.css`, `/css/myStyles.css`)) {
			fh.fromLocalUrl(`css/myStyles.css`)
		}
	}

	Void testAssetUrlMustBeMapped() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(NotFoundErr#, BsErrMsgs.fileHandler_urlNotMapped(`/css/myStyles.css`)) {
			fh.fromLocalUrl(`/css/myStyles.css`)
		}
	}
	
	Void testAssetUrlDoesNotExist() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_fileNotFound(`doc/myStyles.css`.toFile)) {
			fh.fromLocalUrl(`/over-there/myStyles.css`)
		}
		file := fh.service(`/over-there/myStyles.css`)
		verifyNull(file)
	}

	Void testAssetUrl() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc`)
		unNormalised := file.file.uri.relTo(`./`.toFile.normalize.uri) 
		verifyEq(unNormalised, `doc/pod.fdoc`)
	}	

	Void testAcceptsQueryParams() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc?v=4.01`)
		unNormalised := file.file.uri.relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has query params - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc?v=4.01`)
	}	

	Void testAcceptsFragments() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc#v4.01`)
		unNormalised := file.file.uri.relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has fragments - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc#v4.01`)
	}	

	// ---- from Server File ----
	
	Void testAssetFileIsDir() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_notFile(`doc/`.toFile)) {
			fh.fromServerFile(`doc/`.toFile)
		}
	}	
	
	Void testAssetFileDoesNotExist() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_fileNotFound(`doc/booyaa.txt`.toFile)) {
			fh.fromServerFile(`doc/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFileNotMapped() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandler_fileNotMapped(`res/misc/quotes.txt`.toFile)) {
			fh.fromServerFile(`res/misc/quotes.txt`.toFile)
		}
	}
	
	Void testAssetFile() {
		fh  := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		ass := fh.fromServerFile(`doc/pod.fdoc`.toFile)
		verifyEq(ass.clientUrl, `/over-there/pod.fdoc`)
	}

		
	private FileHandler makeFileHandler(Uri:File dirMappings) {
		actorPools := BeanFactory(Type.find("afIoc::ActorPoolsImpl")).add(["afBedSheet.system":ActorPool()]).create
		bil := BeanFactory(FileHandlerImpl#)
		bil.add(dirMappings)
		bil.add(IocEnv.fromStr("dev"))
		bil.add(actorPools)
		bil.setByName("registry", RegistryMock(2))
		bil.setByName("bedServer", BedSheetServerImpl(){})
		
		bob := BeanFactory(FileHandlerImpl#)
		bob.add(dirMappings)
		bob.add(IocEnv.fromStr("dev"))
		bob.add(actorPools)		
		bob.setByName("registry", RegistryMock(bil.create))
		bob.setByName("bedServer", BedSheetServerImpl(){})
		return bob.create
	}
}

internal const class RegistryMock : Registry {
	const Obj service
	new make(Obj service) { this.service = service }
	override This startup()		{ return this }
	override This shutdown()	{ return this }
    override Obj serviceById(Str serviceId) { service }
    override Obj? dependencyByType(Type dependencyType, Bool checked := true) { 2 }
    override Obj autobuild(Type type, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null) { 2 }
	override Obj createProxy(Type mixinType, Type? implType := null, Obj?[]? ctorArgs := null, [Field:Obj?]? fieldVals := null)	{ 2 }
	override Obj injectIntoFields(Obj service) { service }
	override Obj? callMethod(Method method, Obj? instance, Obj?[]? providedMethodArgs := null) { 2 }
}