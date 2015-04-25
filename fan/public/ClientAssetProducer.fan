
** Implement to create custom instances of 'ClientAsset'.
**  
** Instances should be contributed to the 'ClientAssetProducers' service:
**
**   @Contribute { serviceType=ClientAssetProducers# }
**   static Void contributeAssetProducers(Configuration config, MyAssetProducer assetProducer) {
**       config["acme.myAssetProducer"] = assetProducer
**   }
** 
** This ensures your assets will adopt any asset caching strategy set by Cold Feet.
mixin ClientAssetProducer {

	** Creates a 'ClientAsset' from the given local URL.
	**  
	** Returns 'null' if the URL can not be mapped. 
	abstract ClientAsset? produceAsset(Uri localUrl)
	
}
