
internal class TestWebMod : BsTest {
	
	Void testHost() {
		verifyBsErrMsg(BsErrMsgs.startupHostMustHaveSchemeAndAuth(BedSheetConfigIds.host, `dude.com`)) {
			BedSheetWebMod.verifyAndLogHost("APP", `dude.com`)
		}
		verifyBsErrMsg(BsErrMsgs.startupHostMustHaveSchemeAndAuth(BedSheetConfigIds.host, `http:/`)) {
			BedSheetWebMod.verifyAndLogHost("APP", `http:/`)
		}
		verifyBsErrMsg(BsErrMsgs.startupHostMustNotHavePath(BedSheetConfigIds.host, `http://fantomfactory.org/pods`)) {
			BedSheetWebMod.verifyAndLogHost("APP", `http://fantomfactory.org/pods`)
		}
		
		// URIs automatically append a trailing slash to the host, so lets explicitly allow it:
		BedSheetWebMod.verifyAndLogHost("APP", `http://fantomfactory.org/`)
	}
	
}
