
internal class ErrPage {
	
//  ** Handle an error condition during a request.
//  Void onErr(DraftErr err)
//  {
//    // don't spam logs for favicon/robots.txt
//    if (req.uri == `/favicon.ico`) return
//    if (req.uri == `/robots.txt`) return
//
//    // log error
//    logErr(err)
//
//    // pick best err msg
//    msg := err.errCode == 500 && err.cause != null ? err.cause.msg : err.msg
//
//    // setup response if not already commited
//    if (!res.isCommitted)
//    {
//      res.statusCode = err.errCode
//      res.headers["Content-Type"] = "text/html; charset=UTF-8"
//      res.headers["Draft-Err-Msg"] = msg
//    }
//
//    // send HTML response
//    out := res.out
//    out.docType
//    out.html
//    out.head
//      .title.esc(err.msg).titleEnd
//      .style.w("pre,td { font-family:monospace; }
//                td:first-child { color:#888; padding-right:1em; }").styleEnd
//      .headEnd
//    out.body
//      // msg
//      out.h1.esc(err.msg).h1End
//      if (err.msg != msg) out.h2.esc(msg).h2End
//      if (!err.errCode.toStr.startsWith("4"))
//      {
//        out.hr
//        // req headers
//        out.table
//        req.headers.each |v,k| { out.tr.td.w(k).tdEnd.td.w(v).tdEnd.trEnd }
//        out.tableEnd
//        out.hr
//        // stack trace
//        out.pre.w(err.traceToStr).preEnd
//      }
//    out.bodyEnd
//    out.htmlEnd
//  }
//
//  ** Log error.
//  private Void logErr(DraftErr err)
//  {
//    buf := StrBuf()
//    buf.add("$err.msg - $req.uri\n")
//    req.headers.each |v,k| { buf.add("  $k: $v\n") }
//    err.traceToStr.splitLines.each |s| { buf.add("  $s\n") }
//    log.err(buf.toStr.trim)
//  }	
}
