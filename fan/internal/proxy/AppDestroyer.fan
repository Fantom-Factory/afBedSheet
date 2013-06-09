using afIoc::Inject
using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicInt
using web::WebClient

internal const class AppDestroyer {
	private static const Log 	log 			:= Utils.getLog(AppDestroyer#)
	private static const Int	maxNoOfStrikes	:= 2
	
	private const Actor	actor
	private const Int proxyPort
	private const AtomicInt strikes

	@Inject @Config { id="afBedSheet.appDestroyer.pingInterval" }
	private const Duration pingInterval

	new make(ActorPool actorPool, Int proxyPort, |This|in) {
		in(this)
		this.proxyPort 	= proxyPort		
		this.actor 		= Actor(actorPool) |->| { _work() }
		this.strikes	= AtomicInt(0)
	}
	
	Void start() {
		log.info(BsLogMsgs.appDestroyerStarted(pingInterval))
		actor.sendLater(pingInterval, null)
	}

	private Void _work() {
		try {
			client 	:= WebClient()
			client.reqUri = "http://localhost:${proxyPort}${BsConstants.pingUrl}".toUri
			client.writeReq
			client.readRes
			
			resBody	:= client.resIn.readAllStr.trim

			if (client.resCode != 200 || resBody != "OK")
				throw Err(BsLogMsgs.appDestroyerPingNotOk(client.resCode, client.resPhrase))
			
			if (strikes.val > 0) {
				log.info(BsLogMsgs.appDestroyerPingOk)
				strikes.val = 0
			}
			
		} catch (Err e) {
			log.err(e.msg)
			out := strikes.incrementAndGet
			
			// 1x = accident
			// 2x = deliberate
			// 3x = just takes too bloody long!
			if (out >= maxNoOfStrikes) {
				log.err(BsLogMsgs.appDestroyerDESTROY(maxNoOfStrikes))
				
				// BOOM BABY! BOOM!
				Env.cur.exit(69)
			}

			log.warn(BsLogMsgs.appDestroyerStrikeOut(maxNoOfStrikes - out))
		}
		
		actor.sendLater(pingInterval, null)
	}
}
