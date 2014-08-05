using afIoc::RegistryMeta
using web::WebClient

internal class TestMetaData : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testMetaDataIsSet() {
		iocModules = [T_WelcomeMod2#]
		super.setup
		
		meta := (RegistryMeta) registry.serviceById(RegistryMeta#.qname)
		verifyEq(meta["afBedSheet.appModule"], T_WelcomeMod2#)
		verifyEq(meta["afBedSheet.appPod"], this.typeof.pod)
	}
}

internal class T_WelcomeMod2 { }
