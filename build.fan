using build::BuildPod

class Build : BuildPod {
	
	new make() {
		podName = "afBedSheet"
		summary = "A webby framework"
		version = Version([0,0,1])

		meta	= [	"org.name"		: "Alien-Factory",
					"org.uri"		: "http://www.alienfactory.co.uk/",
					"vcs.uri"		: "https://bitbucket.org/SlimerDude/afbedsheet",
					"proj.name"		: "AF-BedSheet",
					"license.name"	: "BSD 2-Clause License",
					"repo.private"	: "true",
			
					"afIoc.module"	: "afBedSheet::BedSheetModule"
				]

		depends = ["sys 1.0", "concurrent 1.0", "web 1.0", "webmod 1.0", "util 1.0",
					"afIoc 0+"]
		srcDirs = [`fan/`, `fan/public/`, `fan/public/services/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/todo/`, `fan/internal/services/`, `fan/config/`]
//		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
