//
//using concurrent
//using util
//using web
//using wisp
//
////////////////////////////////////////////////////////////////////////////
//// DevRestarter
////////////////////////////////////////////////////////////////////////////
//
//** DevRestarter
//const class DevRestarter : Actor
//{
//  new make(ActorPool p, |This| f) : super(p)
//  {
//    f(this)
//  }
//
//  ** Check if pods have been modified.
//  Void checkPods() { send("verify").get(30sec) }
//
//  override Obj? receive(Obj? msg)
//  {
//    if (msg == "verify")
//    {
//      map := Actor.locals["ts"] as Pod:DateTime
//      if (map == null)
//      {
//        startProc
//        Actor.locals["ts"] = update
//      }
//      else if (podsModified(map))
//      {
//        log.info("Pods modified, restarting WispService")
//        stopProc; startProc; Actor.sleep(2sec)
//        Actor.locals["ts"] = update
//      }
//    }
//    return null
//  }
//
//  ** Update pod modified timestamps.
//  private Pod:DateTime update()
//  {
//    map := Pod:DateTime[:]
//    Pod.list.each |p| { map[p] = podFile(p).modified }
//    log.debug("Update pod timestamps ($map.size pods)")
//    return map
//  }
//
//  ** Return pod file for this Pod.
//  private File podFile(Pod pod)
//  {
//    Env? env := Env.cur
//    file := env.workDir + `_doesnotexist_`
//
//    // walk envs looking for pod file
//    while (!file.exists && env != null)
//    {
//      if (env is PathEnv)
//      {
//        ((PathEnv)env).path.eachWhile |p|
//        {
//          file = p + `lib/fan/${pod.name}.pod`
//          return file.exists ? true : null
//        }
//      }
//      else
//      {
//        file = env.workDir + `lib/fan/${pod.name}.pod`
//      }
//      env = env.parent
//    }
//
//    // verify exists and return
//    if (!file.exists) throw Err("Pod file not found $pod.name")
//    return file
//  }
//
//  ** Return true if any pods have been modified since startup.
//  private Bool podsModified(Pod:DateTime map)
//  {
//    true == Pod.list.eachWhile |p|
//    {
//      if (podFile(p).modified > map[p])
//      {
//        log.debug("$p.name pod has been modified")
//        return true
//      }
//      return null
//    }
//  }
//
//  ** Start DraftMod process.
//  private Void startProc()
//  {
//    home := Env.cur.homeDir.osPath
//    args := ["java", "-cp", "${home}/lib/java/sys.jar", "-Dfan.home=$home",
//             "fanx.tools.Fan", "afDraft", "-port", "$port", "-prod"]
//    if (props != null) args.addAll(["-props", props.osPath])
//    args.add(type.qname)
//    proc := Process(args).run
//
//    Actor.locals["proc"] = proc
//    log.debug("Start external process")
//  }
//
//  ** Stop DraftMod process.
//  private Void stopProc()
//  {
//    proc := Actor.locals["proc"] as Process
//    if (proc == null) return
//    proc.kill
//    log.debug("Stop external process")
//  }
//
//  const Type type
//  const Int port
//  const File? props
//  const Log log := Log.get("draft")
//}
//
////////////////////////////////////////////////////////////////////////////
//// DevMod
////////////////////////////////////////////////////////////////////////////
//
//** DevMod
//const class DevMod : WebMod
//{
//  ** Constructor.
//  new make(DevRestarter r)
//  {
//    this.restarter = r
//    this.port = r.port
//  }
//
//  ** Target port to proxy requests to.
//  const Int port
//
//  ** DevRestarter instance.
//  const DevRestarter restarter
//
//  override Void onService()
//  {
//    // check pods
//    restarter.checkPods
//
//    // 13-Jan-2013
//    // Safari seems to have trouble creating seesion cookie
//    // with proxy server - create session here as a workaround
//    dummy := req.session
//
//    // proxy request
//    c := WebClient()
//    c.followRedirects = false
//    c.reqUri = `http://localhost:${port}${req.uri.relToAuth}`
//    c.reqMethod = req.method
//    req.headers.each |v,k|
//    {
//      if (k == "Host") return
//      c.reqHeaders[k] = v
//    }
//    c.writeReq
//
//    is100Continue := c.reqHeaders["Expect"] == "100-continue"
//
//    if (req.method == "POST" && ! is100Continue)
//      c.reqOut.writeBuf(req.in.readAllBuf).flush
//
//    // proxy response
//    c.readRes
//
//    if (is100Continue && c.resCode == 100)
//    {
//      c.reqOut.writeBuf(req.in.readAllBuf).flush
//      c.readRes // final response after the 100continue
//    }
//
//    res.statusCode = c.resCode
//    c.resHeaders.each |v,k| { res.headers[k] = v }
//    if (c.resHeaders["Content-Type"]   != null ||
//        c.resHeaders["Content-Length"] != null)
//      res.out.writeBuf(c.resIn.readAllBuf).flush
//    c.close
//  }
//}
