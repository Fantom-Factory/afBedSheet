using afIoc3::RegistryMeta
using web::WebClient

internal class TestMetaData : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testMetaDataIsSet() {
		iocModules = [T_WelcomeMod2#]
		super.setup
		
		meta := (RegistryMeta) registry.serviceById(RegistryMeta#.qname)
		verifyEq(meta[BsConstants.meta_appModule], T_WelcomeMod2#)
		verifyEq(meta[BsConstants.meta_appPod], this.typeof.pod)
	}
}

internal const class T_WelcomeMod2 { }
