using afIoc

internal class TestBedSheetBuilder : BsTest {
	
	Void testSerialisable() {
		bob := BedSheetBuilder(BedSheetModule#.qname)
		bob.options.set("wot", "ever")
		buf := bob.toStringy
		bob2 := BedSheetBuilder.fromStringy(buf)
		verifyEq(bob2.registryBuilder.moduleTypes, bob.registryBuilder.moduleTypes)
		verifyEq(bob2.options, bob.options)
	}

}
