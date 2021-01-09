using web::WebClient

internal class TestSaveAs : AppTest {
	
	Void testPlain() {
		res := getAsStr(`/saveAs/dude.txt`)
		verifyEq(res, "Short Skirts!")
		verifyEq(client.resHeaders["Content-Type"], "text/plain; charset=utf-8")
		
		// filename needs to be quoted, else Firefox now ignores it
		// 2021-01 - see StackHub's bug report from Sean Rosin of BuildingFit
		// actually - it was an inferred ext from the Content-Type that was overriding the filename
		// but it's still good to quote the filename
		verifyEq(client.resHeaders["Content-Disposition"], "attachment; filename=\"dude.txt\"")
	}	
}
