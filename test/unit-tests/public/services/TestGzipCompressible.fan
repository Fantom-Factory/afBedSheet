
internal class TestGzipCompressible : BsTest {
	
	Void testGzipCompressible() {
		gzip := GzipCompressible([
			MimeType("text/funk")	: true,
			MimeType("text/arse")	: true,
			MimeType("text/bird; feather=blue")	: true,
			MimeType("text/notTonight")	: false
		])

		// test simple
		verify(gzip.isCompressible(MimeType("text/funk")))
		
		// test case-insensitivity
		verify(gzip.isCompressible(MimeType("text/FUNK")))

		// test false
		verifyFalse(gzip.isCompressible(MimeType("text/notTonight")))

		// test not found
		verifyFalse(gzip.isCompressible(MimeType("text/wotever")))

		// test params ignored
		verify(gzip.isCompressible(MimeType("text/bird ; kick=ass")))
	}
	
}
