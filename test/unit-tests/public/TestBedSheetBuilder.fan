using afIoc

internal class TestBedSheetBuilder : BsTest {
	
	Void testSerialisable() {
		bob := BedSheetBuilder(BedSheetModule#.qname, true)
		bob.options.set("wot", "ever")
		buf := Buf()
		buf.out.writeObj(bob)
		buf.flip
		echo(buf.readAllStr)
		bob2 := (BedSheetBuilder) buf.seek(0).in.readObj
		verifyEq(bob2.registryBuilder.moduleTypes, bob.registryBuilder.moduleTypes)
		verifyEq(bob2.options, bob.options)
	}

}
