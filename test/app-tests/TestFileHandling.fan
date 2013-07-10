
internal class TestFileHandling : AppTest {
	
	Void testFileIsServed() {
		text := getAsStr(`/test-src/mr-file.txt`)
		verifyEq(text, "In da house!")
	}

	Void testSpaceFileIsServed() {
		text := getAsStr(`/test-src/name with spaces.txt`)
		verifyEq(text, "Spaces I got!")
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
