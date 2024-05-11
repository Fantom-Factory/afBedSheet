using web

internal class TestMultipartInStream : Test {

	// this test fails
	// see https://fantom.org/forum/topic/2914
	Void XXX_testWeb() {
		bound	:= "XXXXX"
		buf		:= Buf()
		out		:= buf.out

		// GIVEN I have a MultiPart form with x2 fields
		out.print("--").print(bound).print("\r\n")
		out.print("name: foo1\r\n")	// Part1 = foo1
		out.print("\r\n")
		1023.times { out.write(0) }	// 1023 is the MAGIC bad number!
		out.print("\r\n")

		out.print("--").print(bound).print("\r\n")
		out.print("name: foo2\r\n")	// Part2 = foo2
		out.print("\r\n")
		out.print("Data-Data-Data")
		out.print("\r\n")

		out.print("--").print(bound).print("--\r\n")

		// WHEN I parse it with WebUtil
		names	:= Str[,]
		WebUtil.parseMultiPart(buf.flip.in, bound) |headers, InStream in| {
			names.add(headers["name"])
			in.readAllBuf	// drain the part stream
		}
		
		// THEN I should have BOTH field values!
		verifyEq(names, ["foo1", "foo2"])
	}
	
	Void testMultiPartStream() {
		bound	:= "XXXXX"
		buf		:= Buf()
		out		:= buf.out

		// GIVEN I have a MultiPart form with x2 fields
		out.print("--").print(bound).print("\r\n")
		out.print("name: foo1\r\n")	// Part1 = foo1
		out.print("\r\n")
		1023.times { out.write(0) }	// 1023 is the MAGIC bad number!
		out.print("\r\n")

		out.print("--").print(bound).print("\r\n")
		out.print("name: foo2\r\n")	// Part2 = foo2
		out.print("\r\n")
		out.print("Data-Data-Data")
		out.print("\r\n")

		out.print("--").print(bound).print("--\r\n")

		// WHEN I parse it with AFX
		names	:= Str[,]
		AfxMultipartInStream.parseMultipart(buf.flip.in, bound) |headers, InStream in| {
			names.add(headers["name"])
		}
		
		// THEN I should have BOTH field values!
		verifyEq(names, ["foo1", "foo2"])
	}
}
