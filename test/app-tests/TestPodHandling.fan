
internal class TestPodHandling : AppTest {
	
	Str 	 file1_eTag	:= "\"5025-4b4001dcfcd0000\""
	DateTime file1_date	:= DateTime(2010, Month.sep, 27, 09, 46, 40, 0, TimeZone.utc)
	
	Void testFileIsServed() {
		verifyStatus(`/pods/icons/x256/flux.png`, 200)

		verifyEq(client.resHeaders["ETag"], file1_eTag)
		verifyEq(client.resHeaders["Content-Length"], "20517")
		verifyLastModified(file1_date)
	}

	Void test404_1() {
		verify404(`/pods/iconz.png`)
	}

	Void test404_2() {
		verify404(`/pods/iconz/x256/flux.png`)
	}

	Void test404_3() {
		verify404(`/pods/icons/x69/flux.png`)
	}

	Void testFolder() {
		verify404(`/pods/icons/x69/`)
	}
}
