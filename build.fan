using build

class Build : BuildPod {

	new make() {
		podName = "afBedSheet"
		summary = "Something fresh and clean to lay your web app on!"
		version = Version("1.3.12")

		meta = [	
			"proj.name"			: "BedSheet",
			"stackOverflow.tag"	: "afbedsheet",
			"afIoc.module"		: "afBedSheet::BedSheetModule",
			"tags"				: "web",
			"repo.private"		: "false"
		]

		index = [
			"afIoc.module"	: "afBedSheet::BedSheetModule" 
		]

		depends = [
			"sys 1.0", 
			"concurrent 1.0", 
			"web 1.0", 
			"webmod 1.0", // for LogMod
			"wisp 1.0.66+", 
			"util 1.0", 
			"inet 1.0",
	
			// ---- Core ------------------------
			"afBeanUtils 1.0.2+",
			"afConcurrent 1.0.6+",
			"afPlastic 1.0.16+",
			"afIoc 1.7.2+", 
			"afIocConfig 1.0.12.1+", 
			"afIocEnv 1.0.10.1+", 
			
			// ---- Test ------------------------
			"xml 1.0"
		]

		srcDirs = [`test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/utils/`, `test/unit-tests/public/services/`, `test/unit-tests/internal/`, `test/unit-tests/internal/services/`, `test/app-tests/`, `test/app/`, `fan/`, `fan/public/`, `fan/public/utils/`, `fan/public/services/`, `fan/public/responses/`, `fan/public/middleware/`, `fan/public/handlers/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/proxy/`, `fan/internal/processors/`, `fan/internal/middleware/`]
		resDirs = [`res/web/`, `res/misc/`, `res/test/`]
	}
	
	override Void compile() {
		// remove test pods from final build
		testPods := "xml".split
		depends = depends.exclude { testPods.contains(it.split.first) }
		super.compile
	}
}

