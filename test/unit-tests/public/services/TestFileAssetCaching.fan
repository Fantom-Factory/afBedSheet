using afIoc
using afBeanUtils

internal class TestFileAssetCaching : BsTest {
	
	Void testFileHandlerCaching() {
		reg := BedSheetBuilder(T_AppModule#.qname).buildRegistry
		fileHandler	:= (FileHandler) 	reg.serviceById(FileHandler#.qname)
		fileCache	:= (FileAssetCache) reg.serviceById(FileAssetCache#.qname)
		
		verifyEq(fileCache.size, 0)
		
		// check that non-existant files are NOT cached
		asset := fileHandler.fromLocalUrl(`/test-src/missing.wotever`, false)
		verifyEq(asset.exists, false)
		verifyEq(fileCache.size, 0)
		
		asset = fileHandler.fromLocalUrl(`/test-src/mr-file.txt`)
		verifyEq(asset.exists, true)
		verifyEq(fileCache.size, 1)
		
		reg.shutdown
	}

	Void testPodHandlerCaching() {
		reg := BedSheetBuilder(T_AppModule#.qname).buildRegistry
		podHandler	:= (PodHandler) 	reg.serviceById(PodHandler#.qname)
		fileCache	:= (FileAssetCache) reg.serviceById(FileAssetCache#.qname)
		
		verifyEq(fileCache.size, 0)
		
		// check that non-existant files are NOT cached
		verifyErr(ArgErr#) {
			podHandler.fromLocalUrl(`/pods/icons/x256/whoops.png`)
		}
		verifyEq(fileCache.size, 0)
		
		asset := podHandler.fromLocalUrl(`/pods/icons/x256/flux.png`)
		verifyEq(asset.exists, true)
		verifyEq(fileCache.size, 1)
		
		reg.shutdown
	}
}

