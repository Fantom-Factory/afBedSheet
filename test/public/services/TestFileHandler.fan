
internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyErrMsg(BsMsgs.fileHandlerFileNotDir(File(`build.fan`))) {
			fh := FileHandler( [`/wotever/`:File(`build.fan`)] )
		}
	}

	Void testFilesExist() {
		verifyErrMsg(BsMsgs.fileHandlerFileNotExist(File(`wotever`))) {
			fh := FileHandler( [`/wotever/`:File(`wotever`)] )
		}
	}

	Void testUriPathOnly() {
		verifyErrMsg(BsMsgs.fileHandlerUriNotPathOnly(`http://wotever.com`)) {
			fh := FileHandler( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyErrMsg(BsMsgs.fileHandlerUriMustStartWithSlash(`wotever/`)) {
			fh := FileHandler( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUriNotEndWithSlash() {
		verifyErrMsg(BsMsgs.fileHandlerUriMustEndWithSlash(`/wotever`)) {
			fh := FileHandler( [`/wotever`:File(`test/`)] )
		}
	}
	
}
