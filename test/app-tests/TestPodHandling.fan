using afIoc
using afIocConfig

internal class TestPodHandling : AppTest {
	
	Str 	 file1_eTag	:= "\"5025-65f99ff945e5400\""
	DateTime file1_date	:= DateTime(2014, Month.jul, 21, 10, 50, 10, 0, TimeZone.utc)

	override Type[] iocModules	:= [T_AppModule#]
	
	override Void setup() { 
		if (curTestMethod == #testNoPodHandling)
			iocModules.add(T_WelcomeMod3#)
		super.setup
	}

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

	Void testNoPodHandling() {
		verify404(`/pods/icons/x256/flux.png`)
	}
}

internal class T_WelcomeMod3 { 
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(Configuration conf) {
		conf[BedSheetConfigIds.podHandlerBaseUrl] = null
	}
}
