using build

class Build : BuildPod {

	new make() {
		podName = "afBedSheet"
		summary = "A fresh, crisp and clean platform to lay your web app on!"
		version = Version("1.5.9")

		meta = [	
			"pod.dis"			: "BedSheet",
			"stackOverflow.tag"	: "afbedsheet",
			"afIoc.module"		: "afBedSheet::BedSheetModule",
			"repo.tags"			: "web",
			"repo.public"		: "true"
		]

		index = [
			"afIoc.module"	: "afBedSheet::BedSheetModule" 
		]

		depends = [
			"sys        1.0.68 - 1.0", 
			"concurrent 1.0.68 - 1.0", 
			"web        1.0.68 - 1.0", 
			"wisp       1.0.66 - 1.0", 
			"util       1.0.68 - 1.0", 
			"inet       1.0.68 - 1.0",
	
			// ---- Core ------------------------
			"afBeanUtils  1.0.8  - 1.0",
			"afConcurrent 1.0.20 - 1.0",
			"afIoc        3.0.0  - 3.0", 
			"afIocConfig  1.1.0  - 1.1", 
			"afIocEnv     1.1.0  - 1.1", 
			
			// ---- Test ------------------------
			"webmod 1.0",
			"xml    1.0"
		]

		srcDirs = [`fan/`, `fan/internal/`, `fan/internal/middleware/`, `fan/internal/outstream/`, `fan/internal/processors/`, `fan/internal/proxy/`, `fan/internal/utils/`, `fan/public/`, `fan/public/advanced/`, `fan/public/handlers/`, `fan/public/responses/`, `fan/public/services/`, `fan/public/utils/`, `test/app/`, `test/app-tests/`, `test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/services/`, `test/unit-tests/public/utils/`]
		resDirs = [`doc/`, `res/web/`, `res/misc/`, `res/test/`]
		
		meta["afBuild.testPods"]	= "webmod xml"
	}	
}

