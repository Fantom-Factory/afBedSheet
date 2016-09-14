
internal class TestValueEncoders : BsTest {
	
	Void testStrCoerceToNull() {
		enc := ValueEncodersImpl([:])
		
		// the default value of a nullable type should always be null
		verifyNull(enc.toValue(Int?#, ""))
		
		// the problem was, we shortcut'ed the logic for Strings and returned any empty string instead
		verifyNull(enc.toValue(Str?#, ""))
	}
}
