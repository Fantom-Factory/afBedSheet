using afIoc::Inject
using afIocConfig::Config
using web::WebRes

** If the other side closes their connection before we've finished writing, then we get a
**  
**   java.net.SocketException: Connection reset
** 
** As there's nothing we can do about it, we may as well ignore it.
internal class SafeOutStream : OutStream {
	private static const Log log	:= Utils.getLog(SafeOutStream#)
	private OutStream	realOut
	private Bool		socketErr

	new make(OutStream realOut) : super(null) {
		this.realOut 	= realOut
	}

	override This write(Int byte) {
		if (!socketErr)
			try realOut.write(byte)
			catch (Err err) {
				if (!err.msg.contains("java.net.SocketException"))
					throw err
				// means the client closed the socket before we've finished writing data
				socketErr = true
				log.warn(BsLogMsgs.safeOutStream_socketErr(err))
			}
		return this
	}

	override This writeBuf(Buf buf, Int n := buf.remaining()) {
		if (!socketErr)
			try realOut.writeBuf(buf, n)
			catch (Err err) {
				if (!err.msg.contains("java.net.SocketException"))
					throw err
				// means the client closed the socket before we've finished writing data
				socketErr = true
				log.warn(BsLogMsgs.safeOutStream_socketErr(err))
			}
		return this
	}
}
