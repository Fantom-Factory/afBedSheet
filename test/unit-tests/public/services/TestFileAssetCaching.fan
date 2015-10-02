using afIoc3
using afBeanUtils
using afPlastic

internal class TestFileAssetCaching : BsTest {
	
	Void testFileHandlerCaching() {
		reg := BedSheetBuilder(T_AppModule#.qname).addModule(PlasticModule#).build
		fileHandler	:= (FileHandler) 		reg.rootScope.serviceById(FileHandler#.qname)
		assetCache	:= (ClientAssetCache)	reg.rootScope.serviceById(ClientAssetCache#.qname)
		
		verifyEq(assetCache.size, 0)
		
		// check that non-existant files are NOT cached
		asset := fileHandler.fromLocalUrl(`/test-src/missing.wotever`, false)
		verifyNull(asset)
		verifyEq(assetCache.size, 0)
		
		asset = fileHandler.fromLocalUrl(`/test-src/mr-file.txt`)
		verifyEq(asset.exists, true)
		verifyEq(assetCache.size, 1)
		
		reg.shutdown
	}

	Void testPodHandlerCaching() {
		reg := BedSheetBuilder(T_AppModule#.qname).addModule(PlasticModule#).build
		podHandler	:= (PodHandler) 		reg.rootScope.serviceById(PodHandler#.qname)
		assetCache	:= (ClientAssetCache)	reg.rootScope.serviceById(ClientAssetCache#.qname)
		
		verifyEq(assetCache.size, 0)
		
		// check that non-existant files are NOT cached
		verifyErr(ArgErr#) {
			podHandler.fromLocalUrl(`/pods/icons/x256/whoops.png`)
		}
		verifyEq(assetCache.size, 0)
		
		asset := podHandler.fromLocalUrl(`/pods/icons/x256/flux.png`)
		verifyEq(asset.exists, true)
		verifyEq(assetCache.size, 1)
		
		reg.shutdown
	}
}

