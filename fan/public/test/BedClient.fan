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

** For testing: Make (fake) http calls against `BedServer`. Unlike 'WebClient', 'BedClient' is 
** designed for re-use, it auto tracks your 'Cookies' and lets you inspect your session.  
** 
** @since 1.0.4
class BedClient {
	
	private TcpSocket socket	:= TcpSocket()
	private BedServer bedServer
	
	** The session used by the client. Returns 'null' if it has not yet been created.
	WebSession?	session	:= BedSession() {
		get {
			// technically this is not perfect wisp behaviour, for if an obj were to be added then 
			// immediately removed, a wisp session would still be created - pfft! Edge case! 
			// Besides if you need exact wisp behaviour, then use wisp!
			&session.map.isEmpty ? null : &session 
		}
		private set { }
	}

	** The cookies currently amassed by this client.
	** Currently they are not cleared / deleted when max-age runs out.
	Str:Cookie 	cookies	:= Utils.makeMap(Str#, Cookie#)
	
	** The http headers to be sent on the next request. These are cleared after each request. 
	Str:Str		headers	:= Utils.makeMap(Str#, Str#)
	
	** The HTTP version this client should announce to the server. 
	** Defaults to 'HTTP 1.1' 
	Version version			:= Version("1.1")
	
	// TODO: followRedirects
//	Bool followRedirects	:= false
	
	** Create a BedClient attached to the given `BedServer`
	new make(BedServer bedServer) {
		this.bedServer = bedServer
	}
	
	** Makes a (fake) http request against the `BedServer` and returns the response. 
	BedClientRes get(Uri uri, Str method := "GET") {		
		makeReq(
			BedClientReq(cookies.vals) {
				it.version	= this.version
				it.uri		= uri
				it.method	= method
				it.headers	= this.headers
				it.session	= this.&session			
			}			
		)
	}

	// TODO: Post params
//	BedClientRes post(Uri uri, Str method := "POST") {		
//		makeReq(BedClientReq(cookies) {
//			it.version	= this.version
//			it.uri		= uri
//			it.method	= method
//			it.headers	= this.headers
//			it.session	= this.&session
//		})
//	}

	** Shuts down the associated 'BedServer'
	Void shutdown() {
		bedServer.shutdown
	}
	
	private BedClientRes makeReq(BedClientReq bedClientReq) {		
		try {
			bedClientRes := BedClientRes()
			
			Actor.locals["web.req"] = bedClientReq.toWebReq(socket, bedServer)
			Actor.locals["web.res"] = bedClientRes.toWebRes

			httpPipeline := (HttpPipeline) bedServer.registry.dependencyByType(HttpPipeline#)
			httpPipeline.service
			
			bedClientRes.cookies.each |cookie| { this.cookies[cookie.name] = cookie }

			return bedClientRes

		} finally {
			Actor.locals.remove("web.req")
			Actor.locals.remove("web.res")
			headers = Utils.makeMap(Str#, Str#)
		}
	}
}

// this could prob be deleted
internal class BedClientReq {
	Uri uri := `/` {
		set { 
			if (it.auth != null)
				throw Err("URIs must NOT have an authority (scheme, host or port) - $it")
			&uri = it
		}
	}
	Version 	version
	Str 		method
	Str:Str 	headers	
	WebSession 	session
	
	new make(Cookie[] cookies, |This|in) { 
		in(this) 
		headers["Host"] = "localhost:80"
		headers["Cookie"] = cookies.join(";")
	}
	
	internal WebReq toWebReq(TcpSocket socket, BedServer bedServer) {
		BedClientWebReq {
			it.version	= this.version
			it.method	= this.method
			it.uri		= this.uri
			it.headers	= this.headers
			it.session	= this.session
			it.in		= "".in	//throw Err("No content")	// TODO: post reqs & req.inStream 
			it.socket	= socket
		}		
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

** For testing: Holds response data from a (fake) HTTP call to `BedServer`. 
** 
** @since 1.0.4
class BedClientRes {

	** Return the http status code (read-only).
	Int statusCode {
		get { webRes.statusCode }
		private set { }
	}
	
	** Return the http response headers (read-only).
	Str:Str headers		:= Utils.makeMap(Str#, Str#) 	{ private set }

	** Return the http response cookies (read-only).
	** Use this rather than looking for 'Set-Cookie' headers. 
	Cookie[] cookies	:= Cookie[,] 					{ private set }
	
	private Buf 		buf			:= Buf()
	private WebRes 		webRes		:= BedClientWebRes(buf.out) { it.cookies = this.cookies; it.headers = this.headers }
	
	** Return the response stream as a 'Str'.
	Str asStr() {
		buf.flip.in.readAllStr
	}

	** Return the response stream as a 'Buf'.
	Buf asBuf() {
		buf.flip
	}

	** Return the response stream.
	InStream asInStream() {
		buf.flip.in
	}
	
	internal WebRes toWebRes() {
		webRes
	}
}

internal const class BedClientDefaultMod : WebMod { }

** Adapted from WispReq to mimic the same uncommitted behaviour 
internal class BedClientWebRes : WebRes {
	internal WebOutStream webOut

	new make(OutStream outStream, |This|in ) {
		in(this)
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

	override Str:Str headers {
		get { checkUncommitted; return &headers }
	}

	override Cookie[] cookies {
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
	override Void delete() {
		map.clear
	}
}