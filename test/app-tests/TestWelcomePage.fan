using web::WebClient

internal class TestWelcomePage : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testWelcomeAppears() {
		iocModules = [T_WelcomeMod1#]
		super.setup
		
		page := getAsStr(`/wotever`)
		verify(page.contains("Welcome to BedSheet ${typeof.pod.version}!"))
	}

	Void testWelcomeDisappearsWithRoutes() {
		iocModules = [T_AppModule#]
		super.setup
		
		verify404(`/wotever`)
		client = WebClient()
		
		page := getAsStr(`/welcome`)
		verify(page.contains("Welcome to BedSheet ${typeof.pod.version}!"))
	}
	
}

internal class T_WelcomeMod1 { }
