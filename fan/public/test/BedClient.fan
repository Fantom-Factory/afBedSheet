using concurrent::Actor
using afIoc::Registry
using web::Cookie
using web::WebMod
using web::WebOutStream
using web::WebReq
using web::WebRes
using web::WebSession
using web::WebUtil
using inet::IpAddr
using inet::SocketOptions
using inet::TcpSocket

// TODO: let client shutdown the server?
class BedClient {
	
	private TcpSocket socket	:= TcpSocket()
	private BedServer bedServer
	
	WebSession session	:= BedSession()
	
	Version version			:= Version("1.1")
	// TODO: use!
	Bool followRedirects	:= false
	
	new make(BedServer bedServer) {
		this.bedServer = bedServer
	}
	
	BedClientRes get(Uri uri, Str method := "GET") {		
		makeReq(BedClientReq {
			it.version	= this.version
			it.uri		= uri
			it.method	= method
			it.session	= this.session
		})
	}

	** TODO: Post params
	BedClientRes post(Uri uri, Str method := "POST") {		
		makeReq(BedClientReq {
			it.version	= this.version
			it.uri		= uri
			it.session	= this.session
		})
	}

	private BedClientRes makeReq(BedClientReq bedClientReq) {		
		try {
			bedClientRes := BedClientRes()
			
			Actor.locals["web.req"] = bedClientReq.toWebReq(socket, bedServer)
			Actor.locals["web.res"] = bedClientRes.toWebRes

			httpPipeline := (HttpPipeline) bedServer.registry.dependencyByType(HttpPipeline#)
			httpPipeline.service
			
			return bedClientRes

		} finally {
			Actor.locals.remove("web.req")
			Actor.locals.remove("web.res")
		}
	}
	
	private Void reset() {
		
	}
}

class BedClientReq {
	// TODO: need cookies
	Version version
	Str method := "GET"
	Uri uri := `/` {
		// TODO: set check has no scheme and is absolute
	}
	Str:Str headers := Utils.makeMap(Str#, Str#)	
	
	internal WebSession session
	
	new make(|This|in) { 
		in(this) 
		headers["Host"] = "localhost:80"
	}
	
	internal WebReq toWebReq(TcpSocket socket, BedServer bedServer) {
		BedClientWebReq {
			it.version	= this.version
			it.method	= this.method
			it.uri		= this.uri
			it.headers	= this.headers
			it.session	= this.session
			it.in		= "".in	// TODO: wots this? 
			it.socket	= socket
		}		
	}
}

class BedClientRes {
	// TODO: need cookies, status, headers, out
	
	private Buf buf	:= Buf()
	
	Str asStr() {
		buf.flip.in.readAllStr
	}

	Buf asBuf() {
		buf.flip
	}

	InStream asIn() {
		buf.flip.in
	}
	
	internal WebRes toWebRes() {
		BedClientWebRes(buf.out)
	}
}

internal class BedClientWebReq : WebReq {
	TcpSocket socket
	
	override WebMod mod := BedClientDefaultMod()
	override IpAddr remoteAddr() { IpAddr("127.0.0.1") }
	override Int remotePort() { 80 }
	override SocketOptions socketOptions() { socket.options }
	
	override WebSession session
	override Version version
	override Str:Str headers
	override Uri uri
	override Str method
	override InStream in

	new make(|This|in) { in(this) }
}

internal const class BedClientDefaultMod : WebMod { }

** Adapted from WispReq to mimic the same uncommitted behaviour 
internal class BedClientWebRes : WebRes {
	internal WebOutStream webOut

	new make(OutStream outStream) {
		this.headers.caseInsensitive = true
		this.webOut = WebOutStream(outStream)
	}

	override Int statusCode := 200 {
		set {
			checkUncommitted
			if (statusMsg[it] == null) throw Err("Unknown status code: $it");
			&statusCode = it
		}
	}

	override Str:Str headers := Str:Str[:] {
		get { checkUncommitted; return &headers }
	}

	override Cookie[] cookies := Cookie[,] {
		get { checkUncommitted; return &cookies }
	}

	override Bool isCommitted := false { private set }

	override WebOutStream out()	{
		commit
		return webOut
	}

	override Void redirect(Uri uri, Int statusCode := 303) {
		checkUncommitted
		this.statusCode = statusCode
		headers["Location"] = uri.encode
		headers["Content-Length"] = "0"
		commit
		done
	}

	override Void sendErr(Int statusCode, Str? msg := null)	{
		// write message to buffer
		buf := Buf()
		bufOut := WebOutStream(buf.out)
		bufOut.docType
		bufOut.html
		bufOut.head.title.w("$statusCode ${statusMsg[statusCode]}").titleEnd.headEnd
		bufOut.body
		bufOut.h1.w(statusMsg[statusCode]).h1End
		if (msg != null) bufOut.w(msg).nl
		bufOut.bodyEnd
		bufOut.htmlEnd

		// write response
		checkUncommitted
		this.statusCode = statusCode
		headers["Content-Type"] = "text/html; charset=UTF-8"
		headers["Content-Length"] = buf.size.toStr
		this.out.writeBuf(buf.flip)
		done
	}

	override Bool isDone := false { private set }

	override Void done() { isDone = true }

	internal Void checkUncommitted() {
		if (isCommitted) throw Err("WebRes already committed")
	}

	internal Void commit() {
		isCommitted = true
	}

	internal Void close() {
		commit
		webOut.close
	}
}


internal class BedSession : WebSession {
	override const Str id := "69"
	override Str:Obj? map := Str:Obj[:]
	override Void delete()	{
		map.clear
	}
}