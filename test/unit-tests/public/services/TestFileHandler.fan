
internal class TestFileHandler : BsTest {
	
	Void testFilesAreDirs() {
		verifyBsErrMsg(BsMsgs.fileHandlerFileNotDir(File(`build.fan`))) {
			fh := FileHandler( [`/wotever/`:File(`build.fan`)] )
		}
	}

	Void testFilesExist() {
		verifyBsErrMsg(BsMsgs.fileHandlerFileNotExist(File(`wotever`))) {
			fh := FileHandler( [`/wotever/`:File(`wotever`)] )
		}
	}

	Void testUriPathOnly() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriNotPathOnly(`http://wotever.com`)) {
			fh := FileHandler( [`http://wotever.com`:File(`test/`)] )
		}
	}

	Void testUriNotStartWithSlash() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriMustStartWithSlash(`wotever/`)) {
			fh := FileHandler( [`wotever/`:File(`test/`)] )
		}
	}

	Void testUriNotEndWithSlash() {
		verifyBsErrMsg(BsMsgs.fileHandlerUriMustEndWithSlash(`/wotever`)) {
			fh := FileHandler( [`/wotever`:File(`test/`)] )
		}
	}
	
}
