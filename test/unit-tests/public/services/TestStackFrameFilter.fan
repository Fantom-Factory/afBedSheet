
internal class TestStackFrameFilter : BsTest {
	
	Void testFiltering() {
		
		filter := StackFrameFilterImpl([
			"^afIoc::.*\$".toRegex,
			"^fan.sys.Func\\\$Indirect0.call.*\$".toRegex
		])
		
		verifyFalse	(filter.filter("My method afIoc::ServiceMethodInvoker.invokeMethod (AspectInvokerSource.fan:75)"))
		verify		(filter.filter("afIoc::ServiceMethodInvoker.invokeMethod (AspectInvokerSource.fan:75)"))
		verify		(filter.filter("fan.sys.Func\$Indirect0.call (AspectInvokerSource.fan:75)"))
	}
	
}
