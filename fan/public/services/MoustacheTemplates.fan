using afIoc::ConcurrentState
using afIoc::Inject
using mustache::Mustache
using mustache::MustacheParser

** A cache of 'Mustache' templates.
const mixin MoustacheTemplates {
	
	** Renders a Moustache template. The template is cached for future use.
	abstract Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "")

}

internal const class MoustacheTemplatesImpl : MoustacheTemplates {
	
	@Inject @Config { id="afBedSheet.moustache.templateTimeout" }
	private const Duration templateTimeout
	
	private const FileCache 	cache	:= FileCache(templateTimeout)
	
	new make(|This|in) { in(this) }
	
	override Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "") {
		getTemplateFromFile(templateFile).render(context, partials, callStack, indentStr)
	}
	
	private Mustache getTemplateFromFile(File file) {
		cache.getOrAddOrUpdate(file) |->Obj| {
			in 	 := file.in
			tash := Mustache(in)
			in.close
			return tash
		}
	}
}
