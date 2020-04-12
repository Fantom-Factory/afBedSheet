using afIoc

internal class TestBedSheetBuilder : BsTest {
	
	Void testSerialisable() {
		bob := BedSheetBuilder(BedSheetModule#)
		bob.options.set("wot", "ever")
		buf := bob.toStringy
		bob2 := BedSheetBuilder.fromStringy(buf)

//		verifyEq(bob2._moduleTypes, bob._moduleTypes)	// todo make inner fields accessible for test
		
		bob .options.remove("afIoc.bannerText")
		bob2.options.remove("afIoc.bannerText")
		verifyEq(bob2.options, bob.options)
	}

}
