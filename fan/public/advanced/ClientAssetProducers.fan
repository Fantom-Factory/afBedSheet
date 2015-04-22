using afIoc
using afIocEnv
using afConcurrent

@NoDoc	// Advanced use only
const mixin ClientAssetProducers {
	
	abstract ClientAsset? produceAsset(Uri localUrl, Bool checked := true)
	
}


internal const class ClientAssetProducersImpl : ClientAssetProducers {
	
	private const ClientAssetProducer[] producers

	new make(ClientAssetProducer[] producers, |This|? in) {
		this.producers 	= producers
		in?.call(this)
	}
	
	override ClientAsset? produceAsset(Uri localUrl, Bool checked := true) {
		producers.eachWhile { it.fromLocalUrl(localUrl, false) } ?: (
			checked ? throw ArgErr("Could not find or create an ClientAsset for URL `${localUrl}`") : null
		)
	}
}
