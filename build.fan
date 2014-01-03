using build

class Build : BuildPod {

	new make() {
		podName = "afBedSheet"
		summary = "Something fresh and clean to lay your web app on!"
		version = Version("1.2.3")

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"proj.name"		: "BedSheet",
					"proj.uri"		: "http://www.fantomfactory.org/pods/afBedSheet",
					"vcs.uri"		: "https://bitbucket.org/AlienFactory/afbedsheet",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true",

					"afIoc.module"	: "afBedSheet::BedSheetModule"
				]

		index	= [	"afIoc.module"	: "afBedSheet::BedSheetModule" ]

		depends = [	"sys 1.0", 
					"concurrent 1.0", 
					"web 1.0", 
					"webmod 1.0", 
					"wisp 1.0", 
					"util 1.0", 
					"inet 1.0",
			
					"afIoc 1.4.10+", 
					"afIocConfig 0+", 
					"afIocEnv 1+", 
					"afPlastic 1.0+"
				]

		srcDirs = [`test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/utils/`, `test/unit-tests/public/test/`, `test/unit-tests/public/services/`, `test/unit-tests/internal/`, `test/unit-tests/internal/utils/`, `test/unit-tests/internal/services/`, `test/app-tests/`, `test/app/`, `fan/`, `fan/public/`, `fan/public/utils/`, `fan/public/test/`, `fan/public/services/`, `fan/public/responses/`, `fan/public/handlers/`, `fan/public/filters/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/proxy/`, `fan/internal/processors/`, `fan/internal/filters/`]
		resDirs = [`doc/`, `res/web/`, `res/misc/`, `res/test/`]

		docApi = true
		docSrc = true
		
		// exclude test code when building the pod
//		srcDirs = srcDirs.exclude { it.toStr.startsWith("test/") }
//		resDirs = resDirs.exclude { it.toStr.startsWith("res/test/") }
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		super.compile
		
		// copy src to %FAN_HOME% for F4 debugging
		log.indent
		destDir := Env.cur.homeDir.plus(`src/${podName}/`)
		destDir.delete
		destDir.create		
		`fan/`.toFile.copyInto(destDir)		
		log.info("Copied `fan/` to ${destDir.normalize}")
		log.unindent
	}
}

