using concurrent
using afIoc
using afIocEnv
using afBeanUtils::NotFoundErr

internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerFileNotDir(File(`build.fan`))) {
			fh := makeFileHandler( [`/wotever/`:File(`build.fan`)] )
		}
	}

	Void testFilesExist() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerFileNotExist(File(`wotever`))) {
			fh := FileHandlerImpl( [`/wotever/`:File(`wotever`)] )
		}
	}

	Void testUrlPathOnly() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUrlNotPathOnly(`http://wotever.com`, `/foo/bar/`)) {
			fh := FileHandlerImpl( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUrlNotStartWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUrlMustStartWithSlash(`wotever/`, `/foo/bar/`)) {
			fh := FileHandlerImpl( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUrlNotEndWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUrlMustEndWithSlash(`/wotever`)) {
			fh := FileHandlerImpl( [`/wotever`:File(`test/`)] )
		}
	}

	// ---- from Client Uri ----

	Void testAssetUrlIsPathOnly() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUrlNotPathOnly(`http://myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUrl(`http://myStyles.css`, true)
		}
	}

	Void testAssetUrlStartsWithSlash() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUrlMustStartWithSlash(`css/myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUrl(`css/myStyles.css`, true)
		}
	}

	Void testAssetUrlMustBeMapped() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(NotFoundErr#, BsErrMsgs.fileHandlerUrlNotMapped(`/css/myStyles.css`)) {
			fh.fromClientUrl(`/css/myStyles.css`, true)
		}
	}
	
	Void testAssetUrlDoesNotExist() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUrlDoesNotExist(`/over-there/myStyles.css`, `doc/myStyles.css`.toFile)) {
			fh.fromClientUrl(`/over-there/myStyles.css`, true)
		}
		file := fh.fromClientUrl(`/over-there/myStyles.css`, false)
		verifyNull(file)
	}

	Void testAssetUrl() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUrl(`/over-there/pod.fdoc`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri) 
		verifyEq(unNormalised, `doc/pod.fdoc`)
	}	

	Void testAcceptsQueryParams() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUrl(`/over-there/pod.fdoc?v=4.01`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has query params - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc?v=4.01`)
	}	

	Void testAcceptsFragments() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUrl(`/over-there/pod.fdoc#v4.01`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has fragments - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc#v4.01`)
	}	

	// ---- from Server File ----
	
	Void testAssetFileIsDir() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileIsDir(`doc/`.toFile)) {
			fh.fromServerFile(`doc/`.toFile)
		}
	}	
	
	Void testAssetFileDoesNotExist() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileDoesNotExist(`doc/booyaa.txt`.toFile)) {
			fh.fromServerFile(`doc/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFileNotMapped() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileDoesNotExist(`over-here/booyaa.txt`.toFile)) {
			fh.fromServerFile(`over-here/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFile() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		uri := fh.fromServerFile(`doc/pod.fdoc`.toFile)
		verifyEq(uri, `/over-there/pod.fdoc`)
	}

		
	private FileHandler makeFileHandler(Uri:File dirMappings) {
		iocEnv := IocEnv.fromStr("dev")
		actorPools := Type.find("afIoc::ActorPoolsImpl").make([["afBedSheet.system":ActorPool()]])
		func := Field.makeSetFunc([Slot.findField("afBedSheet::FileHandlerImpl.fileCache"):FileMetaCache(iocEnv, actorPools){ }])
		return FileHandlerImpl#.make([dirMappings, func])
	}
}
