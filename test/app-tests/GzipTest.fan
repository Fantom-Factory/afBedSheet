
internal class GzipTest : AppTest {

	Void testGzipCompression() {
		client.reqUri = reqUri(`/gzip`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], "102")
		
		res := Zip.gzipInStream(client.resIn).readAllStr.trim

		verifyEq(res, "This is a gzipped message. No really! It is!")
		
		verifyEq(client.resCode, 200)
		
	}
	
}
