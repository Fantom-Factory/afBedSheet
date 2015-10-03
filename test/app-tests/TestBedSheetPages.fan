using afIoc3
using xml
using web
using inet
using concurrent

internal class TestBedSheetPages : AppTest {
	
	@Inject BedSheetPages? pages
	
	Void testPagesAreValidXml() {
		registry.rootScope.inject(this)
		Actor.locals["web.req"] = T_WebReq()
		Actor.locals["web.res"] = T_WebRes()

		xml := pages.renderHttpStatus(HttpStatus(418, "I'm a teapot"), true).text
		XParser(xml.in).parseDoc

		xml = pages.renderHttpStatus(HttpStatus(418, "I'm a teapot"), false).text
		XParser(xml.in).parseDoc

		xml = pages.renderErr(Err("Whoops!"), true).text
		XParser(xml.in).parseDoc

		xml = pages.renderErr(Err("Whoops!"), false).text
		XParser(xml.in).parseDoc

		xml = pages.renderWelcome.text
		XParser(xml.in).parseDoc
	}
}

internal class T_WebReq : WebReq {
	override WebMod 	mod 				{ get {(Obj)5} set {} }
	override IpAddr remoteAddr()			{ IpAddr("127.0.0.1") }
	override Int remotePort() 				{ 80 }
	override SocketOptions socketOptions()	{ TcpSocket().options }
	override Version 	version				:= Version("1.0")
	override Str 		method				:= "GET"
	override Uri 		uri					:= `/wotever`
	override Str:Str 	headers				:= [:]
	override WebSession	session				:= T_WebSession()
	override InStream 	in					:= "in".toBuf.in
	override TcpSocket	socket()			{ throw Err() }
}

internal class T_WebRes : WebRes {
	override Int statusCode					:= 200
	override Str:Str headers 				:= [:]
	override Cookie[] cookies 				:= [,]
	override Bool isCommitted 				:= false
	override Bool isDone 					:= false
	override Void done() 					{ }
	override WebOutStream out()				{ WebOutStream(Buf().out) }
	override Void redirect(Uri u, Int s := 303)  { }
	override Void sendErr(Int s, Str? m := null) { }
}

internal class T_WebSession : WebSession {
	override const Str id := "69"
	override Str:Obj? map := Str:Obj[:]
	override Void delete() { }
	
	override Void each(|Obj?,Str| f) { map.each(f) }
	@Operator
	override Obj? get(Str name, Obj? def := null) {map.get(name, def)}
	@Operator
	override Void set(Str name, Obj? val) {map.set(name, val) }
	override Void remove(Str name) {map.remove(name) }
}
