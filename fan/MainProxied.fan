using util::Arg
using util::Opt
using util::AbstractMain

@NoDoc
class MainProxied : AbstractMain {

	@Arg { help="A serialized BedSheetBuilder" } 
	private Str? bob

	override Int run() {
		// all our double quotes loose their escaping when the arg is read, so put it back in
		str := "\"" + this.bob.replace("\"", "\\\"") + "\""
		bob	:= BedSheetBuilder.fromString(str)
		prt := bob.options[BsConstants.meta_appPort]
		mod := BedSheetWebMod(bob.buildRegistry)
		return WebModRunner().run(mod, prt)
	}
}
