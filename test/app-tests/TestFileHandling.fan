
internal class TestFileHandling : AppTest {

	Str 	 file1_eTag	:= "\"c-5f5bc1f759d46c0\""
	DateTime file1_date	:= DateTime(2013, Month.aug, 10, 13, 23, 02, 0, TimeZone.utc)
	Str 	 file2_eTag	:= "\"f-5defbcf0039df00\""
	DateTime file2_date	:= DateTime(2013, Month.may, 28, 10, 31, 21, 0, TimeZone.utc)
	
	Void testFileIsServed() {
		text := getAsStr(`/test-src/mr-file.txt`)

		verifyEq(text, "In da house!")
		verifyEq(client.resHeaders["ETag"], file1_eTag)
		verifyLastModified(file1_date)
	}

	Void testSpaceFileIsServed() {
		text := getAsStr(`/test-src/name with spaces.txt`)

		verifyEq(text, "Spaces I got!")
		// TODO: File-Modified test
//		verifyEq(client.resHeaders["ETag"], file2_eTag)
//		verifyLastModified(file2_date)
	}

	Void test404() {
		verify404(`/test-src/gazumped,txt`)
	}

	Void testFolderNonSlash() {
		verifyStatus(`/test-src/folder`, 403)
	}

	Void testFolder() {
		verifyStatus(`/test-src/folder/`, 403)
	}

	Void testSillyUser() {
		verifyStatus(`/test-src2/folder/`, 404)
	}

// TODO: File-Modified test
//	Void testMatchingEtagGives304() {
//		client.reqHeaders["If-None-Match"] = "\"c-5defbca12df6080\""
//		
//		verifyStatus(`/test-src/mr-file.txt`, 304)
//		verifyEq(client.resHeaders["ETag"], "\"c-5defbca12df6080\"")
//		verifyLastModified(file1_date)
//		verifyEq(client.resIn.readAllStr, "")
//	}

// TODO: File-Modified test
//	Void testNewLastModifiedGives304() {
//		client.reqHeaders["If-Modified-Since"] = (file1_date + 1hr).toHttpStr
//		
//		verifyStatus(`/test-src/mr-file.txt`, 304)
//		verifyEq(client.resHeaders["ETag"], "\"c-5defbca12df6080\"")
//		verifyLastModified(file1_date)
//		verifyEq(client.resIn.readAllStr, "")
//	}

	Void testOldLastModifiedSendsFile() {
		client.reqHeaders["If-Modified-Since"] = (file1_date - 1hr).toHttpStr
		text := getAsStr(`/test-src/mr-file.txt`)
		
		verifyEq(text, "In da house!")
		verifyEq(client.resHeaders["ETag"], file1_eTag)
		verifyLastModified(file1_date)
	}
}
