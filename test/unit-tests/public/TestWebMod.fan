
internal class TestWebMod : BsTest {
	
	Void testHost() {
		verifyBsErrMsg(BsErrMsgs.startup_hostMustHaveSchemeAndHost(BedSheetConfigIds.host, `dude.com`)) {
			BedSheetModule.validateHost(`dude.com`)
		}
		verifyBsErrMsg(BsErrMsgs.startup_hostMustHaveSchemeAndHost(BedSheetConfigIds.host, `http:/`)) {
			BedSheetModule.validateHost(`http:/`)
		}
		verifyBsErrMsg(BsErrMsgs.startup_hostMustNotHavePath(BedSheetConfigIds.host, `http://fantomfactory.org/pods`)) {
			BedSheetModule.validateHost(`http://fantomfactory.org/pods`)
		}
		
		// URIs automatically append a trailing slash to the host, so lets explicitly allow it:
		BedSheetModule.validateHost(`http://fantomfactory.org/`)
	}
	
}
