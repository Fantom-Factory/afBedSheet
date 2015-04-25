
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
	** Should throw an Err if the URL is not valid for this asset type, 
	** or return null if 'checked' is 'false'. 
	abstract ClientAsset? fromLocalUrl(Uri localUrl, Bool checked := true)
	
}
