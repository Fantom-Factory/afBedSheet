
** Used by the Err500 page to automatically hide boring and meaningless frames from a stack trace.
** 
** Contribute 'Regex' expressions. 
** A regex must match the whole (trimmed) frame for it to be considered for filtering.
** 
** Example, to remove lines that start with 'afIoc::':
** 
**   syntax: fantom 
**   @Contribute { serviceType=StackFrameFilter# }
**   Void contributeStackFrameFilter(Configuration config) {
**       config.add("^afIoc::.*\$")
**   }
@NoDoc	// Advanced use only
const mixin StackFrameFilter {
	
	** Returns 'true' if the stack frame should be filtered.
	abstract Bool filter(Str frame)
}

internal const class StackFrameFilterImpl : StackFrameFilter {
	private const Regex[] filters
	
	new make(Regex[] filters) {
		this.filters = filters
	}
	
	override Bool filter(Str frame) {
		trimmed := frame.trim
		return filters.any { it.matches(trimmed) }
	}
}
