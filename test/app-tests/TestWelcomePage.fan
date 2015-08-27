using web::WebClient

internal class TestWelcomePage : AppTest {

	override Type[] iocModules	:= [,]
	override Void setup() { }
	
	Void testWelcomeAppears() {
		iocModules = [T_WelcomeMod1#]
		super.setup
		
		verify404(`/wotever`)
		page := client.resIn.readAllStr.trim
		verify(page.contains("Welcome to BedSheet ${typeof.pod.version}!"))

		// check we don't render the 404 after the welcome page! (BugFix - D'Oh!)
		i := page.index("<html")
		verify(i > 0) 
		i = page.index("<html", i+1)
		verifyNull(i)
	}

	Void testWelcomeDisappearsWithRoutes() {
		iocModules = [T_AppModule#]
		super.setup
		
		verify404(`/wotever`)
		client = WebClient()
		verifyErr(IOErr#) {
			// err 'cos there is no body to read
			client.resStr
		}
		
		client = WebClient()
		page := getAsStr(`/welcome`)
		verify(page.contains("Welcome to BedSheet ${typeof.pod.version}!"))
	}
	
}

internal class T_WelcomeMod1 { }
