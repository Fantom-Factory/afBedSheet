using afIoc::NotFoundErr

internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyBsErrMsg(BsErrMsgs.fileHandlerFileNotDir(File(`build.fan`))) {
			fh := FileHandlerImpl( [`/wotever/`:File(`build.fan`)] )
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
		fh := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriNotPathOnly(`http://myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUri(`http://myStyles.css`, true)
		}
	}

	Void testAssetUriStartsWithSlash() {
		fh := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriMustStartWithSlash(`css/myStyles.css`, `/css/myStyles.css`)) {
			fh.fromClientUri(`css/myStyles.css`, true)
		}
	}

	Void testAssetUriMustBeMapped() {
		fh := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(NotFoundErr#, BsErrMsgs.fileHandlerUriNotMapped(`/css/myStyles.css`)) {
			fh.fromClientUri(`/css/myStyles.css`, true)
		}
	}
	
	Void testAssetUriDoesNotExist() {
		fh := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerUriDoesNotExist(`/over-there/myStyles.css`, `doc/myStyles.css`.toFile)) {
			fh.fromClientUri(`/over-there/myStyles.css`, true)
		}
		file := fh.fromClientUri(`/over-there/myStyles.css`, false)
		verifyNull(file)
	}

	Void testAssetUri() {
		fh 	 := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		file := fh.fromClientUri(`/over-there/pod.fandoc`, true)
		unNormalised := file.uri.relTo(`./`.toFile.normalize.uri) 
		verifyEq(unNormalised, `doc/pod.fandoc`)
	}	
	
	// ---- from Server File ----
	
	Void testAssetFileIsDir() {
		fh 	 := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileIsDir(`doc/`.toFile)) {
			fh.fromServerFile(`doc/`.toFile)
		}
	}	
	
	Void testAssetFileDoesNotExist() {
		fh 	 := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileDoesNotExist(`doc/booyaa.txt`.toFile)) {
			fh.fromServerFile(`doc/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFileNotMapped() {
		fh 	 := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileHandlerAssetFileDoesNotExist(`over-here/booyaa.txt`.toFile)) {
			fh.fromServerFile(`over-here/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFile() {
		fh 	 := FileHandlerImpl( [`/over-there/`:File(`doc/`)] )
		uri := fh.fromServerFile(`doc/pod.fandoc`.toFile)
		verifyEq(uri, `/over-there/pod.fandoc`)
	}

}
