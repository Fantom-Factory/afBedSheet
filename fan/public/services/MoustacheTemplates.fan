using afIoc::ConcurrentState
using afIoc::Inject
using mustache::Mustache
using mustache::MustacheParser

** A cache of 'Mustache' templates.
const mixin MoustacheTemplates {
	
	** Renders a Moustache template
	abstract Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "")

}

internal const class MoustacheTemplatesImpl : MoustacheTemplates {
	
	@Inject @Config { id="afBedSheet.moustache.templateTimeout" }
	private const Duration templateTimeout
	
	private const ConcurrentState 	conState	:= ConcurrentState(MoustacheTemplatesState#)
	
	new make(|This|in) { in(this) }
	
	override Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "") {
		getTemplateFromFile(templateFile).render(context, partials, callStack, indentStr)
	}
	
	private Mustache getTemplateFromFile(File templateFile) {
		getState |state->Mustache| {
			key	:= templateFile.uri.toStr
			now := DateTime.now
			
			temp := state.moustacheCache.getOrAdd(key) {
				fromFile(templateFile, now)
			}
			
			if ((now - temp.lastChecked) > templateTimeout) {
				if (templateFile.modified > temp.lastModified) {
					temp = fromFile(templateFile, now)
					state.moustacheCache[key] = temp
				}
			}
			
			return temp.template
		}
	}

	private MoustacheTemplate fromFile(File templateFile, DateTime now) {
		MoustacheTemplate {
			in := templateFile.in
			it.template = Mustache(in)
			it.lastChecked = now
			it.lastModified = now
			in.close
		}		
	}
	
	private Void withState(|MoustacheTemplatesState| state) {
		conState.withState(state)
	}

	private Obj? getState(|MoustacheTemplatesState -> Obj| state) {
		conState.getState(state)
	}
}

internal class MoustacheTemplatesState {
	Str:MoustacheTemplate	moustacheCache	:= [:]
}

internal class MoustacheTemplate {
	DateTime lastChecked
	DateTime lastModified
	Mustache template
	
	new make(|This|f) { f(this) }
}