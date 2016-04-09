using afIoc
using afIocConfig

internal class TestPodHandling : AppTest {
	
	Str 	 file1_eTag	:= "\"5025-71c784f64a9e800\""
	DateTime file1_date	:= DateTime(2016, Month.mar, 27, 17, 59, 00, 0, TimeZone.utc)

	override Type[] iocModules	:= [T_AppModule#]
	
	override Void setup() { 
		if (curTestMethod == #testNoPodHandling)
			iocModules.add(T_WelcomeMod3#)
		super.setup
	}

	Void testFileIsServed() {
		verifyStatus(`/pod/icons/x256/flux.png`, 200)

		verifyEq(client.resHeaders["ETag"], file1_eTag)
		verifyEq(client.resHeaders["Content-Length"], "20517")
		verifyLastModified(file1_date)
	}

	Void test404_1() {
		verify404(`/pod/iconz.png`)
	}

	Void test404_2() {
		verify404(`/pod/iconz/x256/flux.png`)
	}

	Void test404_3() {
		verify404(`/pod/icons/x69/flux.png`)
	}

	Void testFolder() {
		verify404(`/pod/icons/x69/`)
	}

	Void testNoPodHandling() {
		verify404(`/pod/icons/x256/flux.png`)
	}
}

internal const class T_WelcomeMod3 { 
	@Contribute { serviceType=ApplicationDefaults# } 
	static Void contributeApplicationDefaults(Configuration conf) {
		conf[BedSheetConfigIds.podHandlerBaseUrl] = null
	}
}
