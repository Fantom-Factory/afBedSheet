using web::WebUtil

internal class AfxMultipartInStream : InStream {
	InStream	in
	Str			boundary
	Buf			curLine
	Bool		endOfPart
	Bool		endOfParts

	** Parse a multipart/form-data input stream.  For each part in the
	** stream call the given callback function with the part's headers
	** and an input stream used to read the part's body.  Each callback
	** must completely drain the input stream to prepare for the next
	** part. 
	static Void parseMultipart(InStream in, Str boundary, |Str:Str headers, InStream in| cb) {
		boundary = "--" + boundary
		line	:= in.readLine
		if (line == boundary + "--") return
		if (line != boundary) throw IOErr("Multipart form bad boundry, expecting ${boundary} got ${line}")
		while (true) {
			headers := WebUtil.parseHeaders(in)
			partIn	:= AfxMultipartInStream(in, boundary)
			cb(headers, partIn)

			// drain the InStream, in case the user forgets to
			while (partIn.avail > 0)
				partIn.skip(partIn.avail)

			if (partIn.endOfParts) break
		}
	}
	
	private new make(InStream in, Str boundary) : super(null) {
		this.in = in
		this.boundary = boundary
		this.curLine = Buf(1024)
	}
	
	** Only return the num of bytes in *this* part - not the entire request InStream.
	** 
	** Note that this part *may* contain more than 'avail()' bytes.
	override Int avail() {
		gotMoreBytes == false ? 0 : curLine.remaining
	}

	override Int? read() {
		if (gotMoreBytes == false) return null
		return curLine.read
	}

	override Int? readBuf(Buf buf, Int n) {
		if (gotMoreBytes == false) return null
		actualRead := curLine.readBuf(buf, n)
		if (actualRead == null || actualRead == 0)
			return null
		return actualRead
	}

	private Bool gotMoreBytes() {
		// if we have bytes remaining in this line return true
		if (curLine.remaining > 0) return true

		// if we have read boundary, then this part is complete
		if (endOfPart) return false

		// read the next line or 1000 bytes into curLine buf
		curLine.clear
		for (i:=0; i<1024; ++i) {
			c := in.readU1
			curLine.write(c)
			if (c == '\n') break
		}
		
		// boundary condition - make sure \r is available to read on next iteration
		// see https://fantom.org/forum/topic/2914
		if (curLine.size == 1024 && curLine[-1] == '\r') {
			in.unread(curLine[-1])
			curLine.size = curLine.size - 1
			curLine.seek(0)
			return true
		}

		// if not a property \r\n (0x0D 0x0A) newline then return wot we got
		if (curLine.size < 2 || curLine[-2] != '\r') {
			curLine.seek(0)
			return curLine.size > 0
		}

		// go ahead and keep reading as long as we have boundary match
		for (i:=0; i<boundary.size; ++i) {
			c := in.readU1
			if (c != boundary[i]) {
				if (c == '\r') in.unread(c)
				else curLine.write(c)
				curLine.seek(0)
				return true
			}
			curLine.write(c)
		}

		// we have boundary match, so now figure out if end of parts
		curLine.size = curLine.size - boundary.size - 2
		c1 := in.readU1
		c2 := in.readU1
		if (c1 == '-' && c2 == '-') {
			endOfParts = true
			c1 = in.readU1
			c2 = in.readU1
		}
		if (c1 != '\r' || c2 != '\n') throw IOErr("Fishy boundary " + (c1.toChar + c2.toChar).toCode('"', true))
		endOfPart = true
		curLine.seek(0)
		return curLine.size > 0
	}
}
