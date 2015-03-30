using web::WebClient

internal class TestSaveAs : AppTest {
	
	Void testPlain() {
		res := getAsStr(`/saveAs/dude.txt`)
		verifyEq(res, "Short Skirts!")
		verifyEq(client.resHeaders["Content-Type"], "text/plain; charset=utf-8")
		verifyEq(client.resHeaders["Content-Disposition"], "Attachment; filename=dude.txt")
	}	
}
