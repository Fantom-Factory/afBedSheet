using afIoc::ConcurrentState
using afIoc::Inject
using mustache::Mustache
using mustache::MustacheParser

** A cache of 'Mustache' templates.
const mixin MoustacheTemplates {
	
	** Renders a Moustache template.
	abstract Str renderFromStr(Str template, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "")

	** Renders a Moustache template. The template is cached for future use.
	abstract Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "")

}

internal const class MoustacheTemplatesImpl : MoustacheTemplates {
	
	@Inject @Config { id="afBedSheet.moustache.templateTimeout" }
	private const Duration templateTimeout
	
	@Inject	@Config { id="afBedSheet.moustache.linesOfSrcCode" } 	
	private const Int linesOfSrcCode

	private const FileCache 	cache	:= FileCache(templateTimeout)
	
	new make(|This|in) { in(this) }
	
	override Str renderFromStr(Str template, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "") {
		moustache := compile(`Rendered from Str`, template)
		return moustache.render(context, partials, callStack, indentStr)
	}

	override Str renderFromFile(File templateFile, Obj? context := null, [Str:Mustache] partials := [:], Obj?[] callStack := [,], Str indentStr := "") {
		moustache := getTemplateFromFile(templateFile)
		return moustache.render(context, partials, callStack, indentStr)
	}
	
	private Mustache getTemplateFromFile(File file) {
		cache.getOrAddOrUpdate(file) |->Obj| {
			return compile(file.normalize.uri, file.readAllStr)
		}
	}

	private Mustache compile(Uri loc, Str src) {
		try {
			return Mustache(src.in)
			
		} catch (ParseErr err) {
			// the (?s) is to allow '.' to match \n
			reg := Regex<|(?s)^Line ([0-9]+?): (.+)|>.matcher(err.msg)
			if (!reg.find)
				throw err
			
			line 	:= reg.group(1).toInt
			msg 	:= reg.group(2).splitLines.join.replace("\t", " ")	// take out the new line chars
			srcLoc	:= SrcLocation(loc, line, msg, src)
			throw MoustacheErr(srcLoc, msg, linesOfSrcCode)
		}
	}
}
