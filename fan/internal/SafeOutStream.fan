using afIoc::Inject
using afIocConfig::Config
using web::WebRes

** If the other side closes their connection before we've finished writing, then we get a
**  
**   java.net.SocketException: Connection reset
** 
** As there's nothing we can do about it, we may as well ignore it.
** 
** This class is experimental - need to watch the Errs in live to check if it works...
internal class SafeOutStream : OutStream {
	private static const Log log	:= Utils.getLog(SafeOutStream#)
	private OutStream	realOut

	new make(OutStream realOut) : super(null) {
		this.realOut 	= realOut
	}

	override This write(Int byte) {
		try realOut.write(byte)
		catch (Err err) {
			if (!err.msg.contains("java.net.SocketException"))
				throw err
			log.warn(BsLogMsgs.safeOutStream_socketErr(err))
		}
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		try realOut.writeBuf(buf, n)
		catch (Err err) {
			if (!err.msg.contains("java.net.SocketException"))
				throw err
			log.warn(BsLogMsgs.safeOutStream_socketErr(err))
		}
		return this
	}
}
