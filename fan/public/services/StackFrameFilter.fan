
** Removes useless frames from a stack trace. Contribute your useless lines!
@NoDoc
const mixin StackFrameFilter {
	
	** Returns 'true' if the frame should be filtered.
	abstract Bool filter(Str frame)
}

internal const class StackFrameFilterImpl : StackFrameFilter {
	private const Str[] filterFrames
	
	new make(Str[] filterFrames, |This|in) { 
		in(this)
		this.filterFrames = filterFrames.map { it.lower.trim }
	}
	
	override Bool filter(Str frame) {
		lower := frame.lower.trim
		return filterFrames.any { lower.startsWith(it) }
	}
}
