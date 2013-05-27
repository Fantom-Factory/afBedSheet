using web::WebClient

internal class TestJsonResult : AppTest {

	Void testList() {
		res := getAsStr(`/jsonResult/list`)
		verifyEq(res, "[\"this\",\"is\",\"a\",\"json\",\"list\"]")
		verifyEq(client.resHeaders["Content-Type"], "application/json; charset=utf-8")
	}

}
