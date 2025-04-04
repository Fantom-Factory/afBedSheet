using build::BuildPod

class Build : BuildPod {

	new make() {
		podName = "afBedSheet"
		summary = "A framework and IoC container for web applications"
		version = Version("1.5.20")

		meta = [
			"pod.dis"			: "BedSheet",
			"stackOverflow.tag"	: "afbedsheet",
			"afIoc.module"		: "afBedSheet::BedSheetModule",
			"repo.tags"			: "web",
			"repo.public"		: "true"
		]

		depends = [
			"sys          1.0.71 - 1.0",
			"concurrent   1.0.71 - 1.0",
			"web          1.0.71 - 1.0",
			"wisp         1.0.71 - 1.0",
			"util         1.0.71 - 1.0",
			"inet         1.0.71 - 1.0",

			// ---- Core ------------------------
			"afBeanUtils  1.0.10 - 1.0",
			"afConcurrent 1.0.26 - 1.0",
			"afIoc        3.0.6  - 3.0",
			"afIocConfig  1.1.0  - 1.1",
			"afIocEnv     1.1.0  - 1.1",

			// ---- Test ------------------------
			"webmod       1.0",
			"xml          1.0"
		]

		srcDirs = [`fan/`, `fan/internal/`, `fan/internal/middleware/`, `fan/internal/outstream/`, `fan/internal/processors/`, `fan/internal/utils/`, `fan/internal/watchdog/`, `fan/public/`, `fan/public/advanced/`, `fan/public/handlers/`, `fan/public/responses/`, `fan/public/services/`, `fan/public/utils/`, `test/app/`, `test/app-tests/`, `test/unit-tests/`, `test/unit-tests/public/`, `test/unit-tests/public/services/`, `test/unit-tests/public/utils/`]
		resDirs = [`doc/`, `res/web/`, `res/misc/`, `res/test/`]

		meta["afBuild.testPods"]	= "webmod xml"
	}
}
