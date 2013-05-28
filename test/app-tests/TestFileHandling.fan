
internal class TestFileHandling : AppTest {
	
	Void testFileIsServed() {
		verifyEq(getAsStr(`/test-src/mr-file.txt`), "In da house!")
	}

	Void testSpaceFileIsServed() {
		verifyEq(getAsStr(`/test-src/name with spaces.txt`), "Spaces I got!")
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
}
