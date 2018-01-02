
@NoDoc	// Advanced use only
const mixin ClientAssetProducers {
	
	** Implementors should create a new 'ClientAsset' instance each time.
	abstract ClientAsset? produceAsset(Uri localUrl)
}


internal const class ClientAssetProducersImpl : ClientAssetProducers {
	
	private const ClientAssetProducer[] producers

	new make(ClientAssetProducer[] producers, |This|? in) {
		this.producers 	= producers
		in?.call(this)
	}
	
	override ClientAsset? produceAsset(Uri localUrl) {
		producers.eachWhile { it.produceAsset(localUrl) }
	}
}
