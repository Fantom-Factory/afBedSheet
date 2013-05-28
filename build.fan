using build::BuildPod

class Build : BuildPod {
	
	new make() {
		podName = "afBedSheet"
		summary = "Something fresh and clean to lay your web app on!"
		version = Version([0,0,2])

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"vcs.uri"		: "https://bitbucket.org/SlimerDude/afbedsheet",
					"proj.name"		: "AF-BedSheet",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "false",	// Eeek!
			
					"afIoc.module"	: "afBedSheet::BedSheetModule"
				]

		depends = ["sys 1.0", "concurrent 1.0", "web 1.0", "webmod 1.0", "wisp 1.0", "util 1.0", "inet 1.0",
					"afIoc 1.3+"]
		srcDirs = [`test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/services/`, `test/app-tests/`, `test/app/`, `fan/`, `fan/public/`, `fan/public/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/todo/`, `fan/internal/services/`, `fan/internal/processors/`, `fan/internal/encoders/`, `fan/config/`]
//		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
