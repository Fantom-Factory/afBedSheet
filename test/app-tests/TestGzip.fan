
internal class TestGzip : AppTest {

	Void testGzipCompression() {
		client.reqUri = reqUri(`/gzip/big`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes

		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], 	"73")
		verifyEq(client.resHeaders["Vary"], 			"Accept-Encoding")
		
		res := Zip.gzipInStream(client.resIn).readAllStr.trim
		verifyEq(res, "This is a gzipped message. No really! Need 5 more bytes!")
		verifyEq(client.resCode, 200)
	}

	Void testTooSmallForGzipCompression() {
		client.reqUri = reqUri(`/gzip/small`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Content-Length"], "18")
		verifyFalse(client.resHeaders.containsKey("Content-Encoding"))
		
		res := client.resIn.readAllStr.trim
		verifyEq(res, "Too small for gzip")
		verifyEq(client.resCode, 200)
	}

	** @see `http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3`
	Void testOneQualityUsesGzip() {
		client.reqUri = reqUri(`/gzip/big`)
		client.reqHeaders["Accept-encoding"] = "gzip;q=1.0, identity; q=0.5, *;q=0"
		client.writeReq
		client.readRes
		
		verifyEq(client.resHeaders["Content-Encoding"], "gzip")
		verifyEq(client.resHeaders["Content-Length"], 	"73")
		verifyEq(client.resHeaders["Vary"], 			"Accept-Encoding")

		res := Zip.gzipInStream(client.resIn).readAllStr.trim
		verifyEq(res, "This is a gzipped message. No really! Need 5 more bytes!")
		verifyEq(client.resCode, 200)
	}

	** @see `http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3`
	Void testZeroQualityDisablesGzip() {
		client.reqUri = reqUri(`/gzip/big`)
		client.reqHeaders["Accept-encoding"] = "gzip;q=0.0, identity; q=0.5, *;q=0"
		client.writeReq
		client.readRes
		
		verifyFalse(client.resHeaders.containsKey("Content-Encoding"))
		verifyEq(client.resHeaders["Content-Length"], "56")
		
		res := client.resIn.readAllStr.trim
		verifyEq(res, "This is a gzipped message. No really! Need 5 more bytes!")
		verifyEq(client.resCode, 200)
	}

	** @see `http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3`
	Void testResponseDisableGzip() {
		client.reqUri = reqUri(`/gzip/disable`)
		client.reqHeaders["Accept-encoding"] = "gzip"
		client.writeReq
		client.readRes
		
		verifyFalse(client.resHeaders.containsKey("Content-Encoding"))
		verifyEq(client.resHeaders["Content-Length"], "60")
		
		res := client.resIn.readAllStr.trim
		verifyEq(res, "This is NOT a gzipped message. No really! Need 5 more bytes!")
		verifyEq(client.resCode, 200)
	}
}
