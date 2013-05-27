
internal class GzipTest : AppTest {

	Void testGzipCompression() {
		client.reqUri = reqUri(`/gzip/big`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], 	"74")
		
		res := Zip.gzipInStream(client.resIn).readAllStr.trim
		verifyEq(res, "This is a gzipped message. No really! Need 5 more bytes!")
		verifyEq(client.resCode, 200)
	}

	Void testTooSmallForGzipCompression() {
		client.reqUri = reqUri(`/gzip/small`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Content-Length"], 	"19")
		verifyFalse(client.resHeaders.containsKey("Content-Encoding"))
		
		res := client.resIn.readAllStr.trim
		verifyEq(res, "Too small for gzip")
		verifyEq(client.resCode, 200)
	}
	
}
