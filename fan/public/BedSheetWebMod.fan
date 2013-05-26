using concurrent::AtomicRef
using web
using afIoc

const class BedSheetWebMod : WebMod {

	const Str moduleName
	const Bool devMode
	
	const AtomicRef	registry	:= AtomicRef()
	
	Registry reg {
		get { registry.val }
		set { }
	}
	
	// pass registry startup optoins?
	new make(Str moduleName, Bool devMode) {
		this.moduleName = moduleName
		this.devMode	= devMode
	}
	
	
	override Void onService() {
		req.mod = this
		stashManager := (ThreadStashManager) reg.dependencyByType(ThreadStashManager#)

		try {
			router 		:= (Router) reg.dependencyByType(Router#)
			routeMatch	:= router.match(req.modRel, req.method)

			// save the routeMatch so it can be picked up by `Request`
			req.stash["bedSheet.routeMatch"] = routeMatch 

			if (routeMatch == null)
				throw HttpErr(404, BsMsgs.routeNotFound(req.modRel))

			handler	:= (RouteHandler) reg.dependencyByType(RouteHandler#)
			result	:= handler.handle(routeMatch)

			// TODO: true is okay, void is warn, null is err
			if (result != null) {
				resProSrc	:= (ResultProcessorSource) reg.dependencyByType(ResultProcessorSource#)
				resPro 		:= resProSrc.getResultProcessor(result.typeof)
				resPro.process(result)
			}

			// don't flush or close because if, say for example, we send a 304 Not Modified, then 
			// there's nothing to close!
//			res.out.flush
//			res.out.close
			
			// TODO: have a HttpStatus handler? 
			
		} catch (HttpErr err) {
			
			// TODO: have status code handlers
			res.sendErr(err.statusCode, err.msg)
			
		} catch (Err err) {
			
			// TODO: have Err handlers
			
			buf:=StrBuf()
			err.trace(Env.cur.out, ["maxDepth":500])
			
			// TODO: contribute Err handlers
//			onErr(err)
		} finally {
			stashManager.cleanUp
		}
	}
	
	override Void onStart() {
		// TODO: log BedSheet version

		bob := RegistryBuilder()

		// TODO: wrap up in try 
		pod := Pod.find(moduleName, false)
		mod := (pod == null) ? Type.find(moduleName, false) : null

		
		if (pod != null)
			bob.addModulesFromDependencies(pod, true)
		
		if (mod != null) {
			bob.addModule(BedSheetModule#)
			bob.addModule(mod)
		}
		
		reg := bob.build.startup
		
		registry.val = reg
		
		// validate routes on startup
		reg.dependencyByType(Router#)
	}

	override Void onStop() {
		Env.cur.err.printLine("Goodbye!")	//TODO:log
		reg := (Registry?) registry.val
		reg?.shutdown
	}
}
