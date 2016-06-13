
internal class TestErrPrinterStr : BsTest {
	
	Void testPrintCauses() {
		err := ArgErr("Ouch!", ArgErr("Ouch!", Err("Wotever", ArgErr("Ouch!", ArgErr("Ouch!")))))
		str := ErrPrinterStrSections.isolateCauses(err).join("\n")
		
		// verify repeated cause msgs are removed
		verifyEq(str, "sys::ArgErr
		               sys::ArgErr - Ouch!
		               sys::Err - Wotever
		               sys::ArgErr
		               sys::ArgErr - Ouch!")
	}
	
	Void testPrintStackTrace() {
		err := TestToStrErr("Ouch!", "-= argh =-", TestToStrErr("Boo!", "-= boo =-\n..shite.."))
		fms := ErrPrinterStrSections.isolateStackFrames(err, 3)
		
		verifyEq(fms[0].size, 4)
		verifyEq(fms[0][0], "afBedSheet::TestToStrErr: Ouch!")

		verifyEq(fms[1].size, 6)
		verifyEq(fms[1][0], "")
		verifyEq(fms[1][1], "Cause:")
		verifyEq(fms[1][2], "afBedSheet::TestToStrErr: Boo!")
	}
	
}

internal const class TestToStrErr : Err {
	const Str str

	new make(Str msg, Str toStr, Err? cause := null) : super(msg, cause) {
		str = toStr
	}
	
	override Str toStr() {
		str + "\n" + super.toStr
	}
}