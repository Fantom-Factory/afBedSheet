
internal class TestRoute : BsTest {
	
	Void testUriPathOnly() {
		verifyErrMsg(BsMsgs.routeShouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := Route(`http://www.alienfactory.co.uk/`, #foo)
		}

		verifyErrMsg(BsMsgs.routeShouldBePathOnly(`/foo/bar?kick=ass`)) {
			r := Route(`/foo/bar?kick=ass`, #foo)
		}
	}

	Void testUriStartWithSlash() {
		verifyErrMsg(BsMsgs.routeShouldStartWithSlash(`foo/bar`)) {
			r := Route(`foo/bar`, #foo)
		}
	}

	Void foo() { }
}
