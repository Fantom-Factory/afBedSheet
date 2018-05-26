
** Implement to create custom instances of 'ClientAsset'.
**  
** Producer instances should be contributed to the 'ClientAssetProducers' service:
**
**   syntax: fantom 
**   @Contribute { serviceType=ClientAssetProducers# }
**   Void contributeAssetProducers(Configuration config, MyAssetProducer assetProducer) {
**       config["acme.myAssetProducer"] = assetProducer
**   }
** 
** Asset caching strategies, like Cold Feet, use the 'ClientAssetProducers' service to modify the client URLs of 'ClientAssets'. 
mixin ClientAssetProducer {

	** Creates a 'ClientAsset' from the given local URL.
	**  
	** Implementors should return 'null' if the URL can not be mapped. 
	abstract ClientAsset? produceAsset(Uri localUrl)
	
}
