
internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyBsErrMsg(BsMsgs.fileHandlerFileNotDir(File(`build.fan`))) {
			fh := FileHandlerImpl( [`/wotever/`:File(`build.fan`)] )
		}
	}

	Void testFilesExist() {
		verifyBsErrMsg(BsMsgs.fileHandlerFileNotExist(File(`wotever`))) {
			fh := FileHandlerImpl( [`/wotever/`:File(`wotever`)] )
		}
	}

	Void testUriPathOnly() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriNotPathOnly(`http://wotever.com`)) {
			fh := FileHandlerImpl( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriMustStartWithSlash(`wotever/`)) {
			fh := FileHandlerImpl( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUriNotEndWithSlash() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriMustEndWithSlash(`/wotever`)) {
			fh := FileHandlerImpl( [`/wotever`:File(`test/`)] )
		}
	}
	
}
