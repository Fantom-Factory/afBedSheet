
internal class servicePod {
	
//	  ** Service a pod request.
//  private Void onServicePod()
//  {
//    // must have at least 3 path segments
//    path := req.uri.path
//    if (path.size < 2) throw DraftErr(404)
//
//    // lookup pod
//    pod := Pod.find(path[1], false)
//    if (pod == null) throw DraftErr(404)
//
//    // lookup file
//    file := pod.file(`/` + req.uri[2..-1], false)
//    if (file == null) throw DraftErr(404)
//    FileWeblet(file).onService
//  }

	static Void main(Str[] args) {
		f:=Pod.find("icons").file(`fan://icons/x16/cut.png`)
		Env.cur.err.printLine(f.osPath)
		Env.cur.err.printLine(f.toStr)
	}
	
}
