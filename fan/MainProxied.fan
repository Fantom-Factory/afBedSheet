using util::Arg
using util::Opt
using util::AbstractMain

@NoDoc
class MainProxied : AbstractMain {

	// not used directly - Ioc Env checks the start args 
	@Opt { help="The environment to start BedSheet in -> dev|test|prod" }
	private Str? env

	@Arg { help="A serialized BedSheetBuilder" } 
	private Str? bob

	override Int run() {
		// all our double quotes loose their escaping when the arg is read, so put it back in
		str := "\"" + this.bob.replace("\"", "\\\"") + "\""
		bob	:= BedSheetBuilder.fromStr(str)
		prt := bob.options["afBedSheet.appPort"]
		mod := BedSheetWebMod(bob.build)
		return WebModRunner().run(mod, prt)
	}
}
