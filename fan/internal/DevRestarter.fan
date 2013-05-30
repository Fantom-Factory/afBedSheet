using afIoc::ConcurrentState
using concurrent::Actor
using util
using web
using wisp

** Adapted from 'draft'
internal const class DevRestarter {
	private const static Log 		log 		:= Utils.getLog(DevRestarter#)
	private const ConcurrentState 	conState	:= ConcurrentState(DevRestarterState#)
	
	const Str appModule
	const Int port
	
	new make(Str appModule, Int port) { 
		this.appModule = appModule
		this.port = port
	}

	Void initialise() {
		withState |state| {
			if (state.realWebApp == null) {
				state.startRealWebApp(appModule, port)
				state.updateTimeStamps
			}
		}
	}
	
	** Check if pods have been modified.
	Void checkPods() {
		withState |state| {
			if (state.podsModified) {
				log.info("Pods modified, restarting WispService")
				state.stopRealWebApp
				state.startRealWebApp(appModule, port)
				Actor.sleep(2sec)
				state.updateTimeStamps
			}
		}
		// TODO: update afIoc and change to
//		getFuture { ... }.get(30sec)
	}
	
	private Void withState(|DevRestarterState| state) {
		conState.withState(state)
	}
}

internal class DevRestarterState {
	private const static Log log := Utils.getLog(DevRestarter#)
	
	Pod:DateTime?	podTimeStamps	:= [:]
	Process?		realWebApp

	Void updateTimeStamps() {
		Pod.list.each |p| { podTimeStamps[p] = podFile(p).modified }
		log.debug("Updated ${podTimeStamps.size} pods pod timestamps")
	}
	
	Bool podsModified()	{
		true == Pod.list.eachWhile |p| {
			if (podFile(p).modified > podTimeStamps[p]) {
				log.debug("$p.name pod has been modified")
				return true
			}
			return null
		}
	}
	
	Void startRealWebApp(Str appModule, Int port) {
		log.debug("Starting real app $appModule")
		home := Env.cur.homeDir.osPath
		args := "java -cp ${home}/lib/java/sys.jar -Dfan.home=$home fanx.tools.Fan afBedSheet $appModule $port".split
		realWebApp = Process(args).run
	}

	Void stopRealWebApp()	{
		log.debug("Stop external process")
		if (realWebApp == null)
			return
		realWebApp.kill
	}
	
	private File podFile(Pod pod) {
		Env? env := Env.cur
		file := env.workDir + `_doesnotexist_`

		// walk envs looking for pod file
		while (!file.exists && env != null) {
			if (env is PathEnv) {
				((PathEnv)env).path.eachWhile |p| {
					file = p + `lib/fan/${pod.name}.pod`
					return file.exists ? true : null
				}
			} else {
				file = env.workDir + `lib/fan/${pod.name}.pod`
			}
			env = env.parent
		}

		// verify exists and return
		if (!file.exists) throw Err("Pod file not found $pod.name")
		return file
	}	
}

** Currently taken from 'draft'
internal const class DevProxyMod : WebMod {

	** Target port to proxy requests to.
	const Int devPort
	const DevRestarter restarter
	
	new make(Str appModule, Int realPort) {
		this.devPort = realPort + 1
		this.restarter = DevRestarter(appModule, devPort)
	}

	override Void onStart() {
		restarter.initialise		
	}
	
	override Void onService() {
		restarter.checkPods

		// 13-Jan-2013
		// Safari seems to have trouble creating seesion cookie
		// with proxy server - create session here as a workaround
		dummy := req.session

		// proxy request
		c := WebClient()
		c.followRedirects = false
		c.reqUri = `http://localhost:${devPort}${req.uri.relToAuth}`
		c.reqMethod = req.method
		req.headers.each |v,k| {
			if (k == "Host") return
			c.reqHeaders[k] = v
		}
		c.writeReq

		is100Continue := c.reqHeaders["Expect"] == "100-continue"

		if (req.method == "POST" && ! is100Continue)
			c.reqOut.writeBuf(req.in.readAllBuf).flush

		// proxy response
		c.readRes

		if (is100Continue && c.resCode == 100) {
			c.reqOut.writeBuf(req.in.readAllBuf).flush
			c.readRes // final response after the 100continue
		}

		res.statusCode = c.resCode
		c.resHeaders.each |v,k| { res.headers[k] = v }
		if (c.resHeaders["Content-Type"]	!= null ||
			c.resHeaders["Content-Length"] 	!= null)
			res.out.writeBuf(c.resIn.readAllBuf).flush
		c.close
	}
}
