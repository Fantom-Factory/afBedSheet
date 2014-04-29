
internal class TestFileHandling : AppTest {
	File	file1	:= `test/app-web/mr-file.txt`.toFile
	File	file2	:= `test/app-web/name with spaces.txt`.toFile
	
	Void testFileIsServed() {
		text := getAsStr(`/test-src/mr-file.txt`)

		verifyEq(text, "In da house!")
		verifyEq(client.resHeaders["ETag"], etag(file1))
		verifyLastModified(file1.modified)
	}

	Void testSpaceFileIsServed() {
		text := getAsStr(`/test-src/name with spaces.txt`)

		verifyEq(text, "Spaces I got!")
		verifyEq(client.resHeaders["ETag"], etag(file2))
		verifyLastModified(file2.modified)
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

	Void testMatchingEtagGives304() {
		client.reqHeaders["If-None-Match"] = etag(file1)
		
		verifyStatus(`/test-src/mr-file.txt`, 304)
		verifyEq(client.resHeaders["ETag"], etag(file1))
		verifyLastModified(file1.modified)
		verifyEq(client.resIn.readAllStr, "")
	}

	Void testNewLastModifiedGives304() {
		client.reqHeaders["If-Modified-Since"] = (file1.modified + 1hr).toHttpStr
		
		verifyStatus(`/test-src/mr-file.txt`, 304)
		verifyEq(client.resHeaders["ETag"], etag(file1))
		verifyLastModified(file1.modified)
		verifyEq(client.resIn.readAllStr, "")
	}

	Void testOldLastModifiedSendsFile() {
		client.reqHeaders["If-Modified-Since"] = (file1.modified - 1hr).toHttpStr
		text := getAsStr(`/test-src/mr-file.txt`)
		
		verifyEq(text, "In da house!")
		verifyEq(client.resHeaders["ETag"], etag(file1))
		verifyLastModified(file1.modified)
	}
	
	private Str etag(File file) {
		"\"${file.size.toHex}-${file.modified.ticks.toHex}\""
	}
}
