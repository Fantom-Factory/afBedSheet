using build

class Build : BuildPod {

	new make() {
		podName = "afBedSheet"
		summary = "A fresh, crisp and clean platform to lay your web app on!"
		version = Version("1.4.15")

		meta = [	
			"proj.name"			: "BedSheet",
			"stackOverflow.tag"	: "afbedsheet",
			"afIoc.module"		: "afBedSheet::BedSheetModule",
			"repo.tags"			: "web",
			"repo.public"		: "false"
		]

		index = [
			"afIoc.module"	: "afBedSheet::BedSheetModule" 
		]

		depends = [
			"sys        1.0", 
			"concurrent 1.0", 
			"web        1.0", 
			"webmod     1.0", // for LogMod
			"wisp       1.0.66 - 1.0", 
			"util       1.0", 
			"inet       1.0",
	
			// ---- Core ------------------------
			"afBeanUtils  1.0.4  - 1.0",
			"afConcurrent 1.0.8  - 1.0",
			"afPlastic    1.0.19 - 1.0",	// FIXME: update to 1.0.20
//			"afIoc        2.0.6  - 2.0", 
			"afIoc3       3.0.0  - 3.0", 
			"afIocConfig  1.0.16 - 1.0", 
			"afIocEnv     1.0.18 - 1.0", 
			
			// ---- Test ------------------------
			"xml 1.0"
		]

		srcDirs = [`test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/utils/`, `test/unit-tests/public/services/`, `test/app-tests/`, `test/app/`, `fan/`, `fan/public/`, `fan/public/utils/`, `fan/public/services/`, `fan/public/responses/`, `fan/public/handlers/`, `fan/public/advanced/`, `fan/internal/`, `fan/internal/utils/`, `fan/internal/services/`, `fan/internal/proxy/`, `fan/internal/processors/`, `fan/internal/middleware/`, `fan/afConcurrent/`]
		resDirs = [`doc/`, `res/web/`, `res/misc/`, `res/test/`]
	}
	
	override Void compile() {
		// remove test pods from final build
		testPods := "xml".split
		depends = depends.exclude { testPods.contains(it.split.first) }
		super.compile
	}
}

