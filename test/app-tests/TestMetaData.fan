using web::WebClient

internal class TestMetaData : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testMetaDataIsSet() {
		iocModules = [T_WelcomeMod2#]
		super.setup
		
		meta := (BedSheetMetaData) registry.dependencyByType(BedSheetMetaData#)
		verifyEq(meta.appModule, T_WelcomeMod2#)
		verifyEq(meta.appPod, this.typeof.pod)
	}
}

internal class T_WelcomeMod2 { }
