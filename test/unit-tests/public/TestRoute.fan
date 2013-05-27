
internal class TestRoute : BsTest {
	
	Void testUriPathOnly() {
		verifyBsErrMsg(BsMsgs.routeShouldBePathOnly(`http://www.alienfactory.co.uk/`)) {
			r := Route(`http://www.alienfactory.co.uk/`, #foo)
		}

		verifyBsErrMsg(BsMsgs.routeShouldBePathOnly(`/foo/bar?kick=ass`)) {
			r := Route(`/foo/bar?kick=ass`, #foo)
		}
	}

	Void testUriStartWithSlash() {
		verifyBsErrMsg(BsMsgs.routeShouldStartWithSlash(`foo/bar`)) {
			r := Route(`foo/bar`, #foo)
		}
	}

	Void foo() { }
}
