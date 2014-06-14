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

	Void testUriPathOnly() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUriNotPathOnly(`http://wotever.com`, `/foo/bar/`)) {
			fh := FileHandlerImpl( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUriMustStartWithSlash(`wotever/`, `/foo/bar/`)) {
			fh := FileHandlerImpl( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUriNotEndWithSlash() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerUriMustEndWithSlash(`/wotever`)) {
			fh := FileHandlerImpl( [`/wotever`:File(`test/`)] )
		}
	}

	// ---- from Client Uri ----

	Void testAssetUriIsPathOnly() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriNotPathOnly(`http://myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUri(`http://myStyles.css`, true)
		}
	}

	Void testAssetUriStartsWithSlash() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriMustStartWithSlash(`css/myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUri(`css/myStyles.css`, true)
		}
	}

	Void testAssetUriMustBeMapped() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(NotFoundErr#, BsErrMsgs.fileHandlerUriNotMapped(`/css/myStyles.css`)) {
			fh.fromClientUri(`/css/myStyles.css`, true)
		}
	}
	
	Void testAssetUriDoesNotExist() {
		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriDoesNotExist(`/over-there/myStyles.css`, `doc/myStyles.css`.toFile)) {
			fh.fromClientUri(`/over-there/myStyles.css`, true)
		}
		file := fh.fromClientUri(`/over-there/myStyles.css`, false)
		verifyNull(file)
	}

	Void testAssetUri() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUri(`/over-there/pod.fdoc`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri) 
		verifyEq(unNormalised, `doc/pod.fdoc`)
	}	

	Void testAcceptsQueryParams() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUri(`/over-there/pod.fdoc?v=4.01`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has query params - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc?v=4.01`)
	}	

	Void testAcceptsFragments() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUri(`/over-there/pod.fdoc#v4.01`, true)
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
