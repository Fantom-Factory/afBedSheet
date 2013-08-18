using afIoc
using mustache

internal class TestMoustacheErr : BsTest {
	
	@Inject	private MoustacheTemplates? templates
	
	Void testStuff() {
		reg := RegistryBuilder().addModules([BedSheetModule#, MoustacheModule#]).build.startup
		reg.injectIntoFields(this)
		
		src := 
		"""<html>
		   <head>
		   	<title>{{ title }}</title>
		   	<style>
		   		{{{ bedSheetCss }}}
		   	</style>
		   </head>
		   <body>	
		   	<header>
		   		{{{ alienHeadSvg } dude!
		   		<span class="brand">{{ title }}</span>
		   	</header>

		   	<main>
		   		{{{ content }}}
		   	</main>

		   	<footer>
		   		<a href="http://repo.status302.com/doc/afBedSheet/#overview">Alien-Factory BedSheet {{ version }}</a>
		   	</footer>
		   </body>
		   """
		
		try {
			templates.renderFromStr(src)
			fail
		} catch (MoustacheErr err) {
			verifyEq(err.srcLoc.errLine, 10)
		}
	}	
}


