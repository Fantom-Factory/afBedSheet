using afIoc
using afBeanUtils

internal class TestFileHandler : BsTest {
	
//	Void testFilesAreDirs() {
//		verifyBsErrMsg(BsErrMsgs.fileIsNotDirectory(File(`build.fan`))) {
//			makeFileHandler( [`/wotever/`:File(`build.fan`)] )
//		}
//	}
//
//	Void testFilesExist() {
//		verifyBsErrMsg(BsErrMsgs.fileNotFound(File(`wotever`))) {
//			makeFileHandler( [`/wotever/`:File(`wotever`)] )
//		}
//	}
//
//	Void testUrlPathOnly() {
//		verifyBsErrMsg(BsErrMsgs.urlMustBePathOnly(`http://wotever.com`, `/foo/bar/`)) {
//			makeFileHandler( [`http://wotever.com`:File(`test/`)] )
//		}
//	}
//
//	Void testUrlNotStartWithSlash() {
//		verifyBsErrMsg(BsErrMsgs.urlMustStartWithSlash(`wotever/`, `/foo/bar/`)) {
//			makeFileHandler( [`wotever/`:File(`test/`)] )
//		}
//	}
//
//	Void testUrlNotEndWithSlash() {
//		verifyBsErrMsg(BsErrMsgs.urlMustEndWithSlash(`/wotever`, `/foo/bar/`)) {
//			makeFileHandler( [`/wotever`:File(`test/`)] )
//		}
//	}
//
//	// ---- fromLocalUrl() ----
//
//	Void testAssetUrlIsPathOnly() {
//		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
//		verifyErrMsg(ArgErr#, BsErrMsgs.urlMustBePathOnly(`http://myStyles.css`, `/css/myStyles.css`)) {
//			fh.fromLocalUrl(`http://myStyles.css`)
//		}
//	}
//
//	Void testAssetUrlStartsWithSlash() {
//		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
//		verifyErrMsg(ArgErr#, BsErrMsgs.urlMustStartWithSlash(`css/myStyles.css`, `/css/myStyles.css`)) {
//			fh.fromLocalUrl(`css/myStyles.css`)
//		}
//	}
//
//	Void testAssetUrlMustBeMapped() {
//		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
//		verifyErrMsg(BedSheetNotFoundErr#, BsErrMsgs.fileHandler_urlNotMapped(`/css/myStyles.css`)) {
//			fh.fromLocalUrl(`/css/myStyles.css`)
//		}
//	}
//	
//	Void testAssetUrlDoesNotExist() {
//		fh := makeFileHandler( [`/over-there/`:File(`doc/`)] )
//		verifyErrMsg(ArgErr#, BsErrMsgs.fileNotFound(`doc/myStyles.css`.toFile)) {
//			fh.fromLocalUrl(`/over-there/myStyles.css`)
//		}
//		file := fh.serviceRoute(`/over-there/myStyles.css`)
//		verifyNull(file)
//	}

	Void testAssetUrl() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc`)
		unNormalised := file->file->uri->relTo(`./`.toFile.normalize.uri)
		verifyEq(unNormalised, `doc/pod.fdoc`)
	}	

	Void testAcceptsQueryParams() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc?v=4.01`)
		unNormalised := file->file->uri->relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has query params - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc?v=4.01`)
	}	

	Void testAcceptsFragments() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		file := fh.fromLocalUrl(`/over-there/pod.fdoc#v4.01`)
		unNormalised := file->file->uri->relTo(`./`.toFile.normalize.uri)
		// it doesn't seem to matter that the File has fragments - it can still be read!
		verifyEq(unNormalised, `doc/pod.fdoc#v4.01`)
	}	

	// ---- fromServerFile() ----
	
	Void testAssetFileIsDir() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(HttpStatusErr#, BsErrMsgs.directoryListingNotAllowed(`/over-there/`)) {
			fh.fromServerFile(`doc/`.toFile)
		}
	}	
	
	Void testAssetFileDoesNotExist() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(ArgErr#, BsErrMsgs.fileNotFound(`doc/booyaa.txt`.toFile)) {
			fh.fromServerFile(`doc/booyaa.txt`.toFile)
		}
	}
	
	Void testAssetFileNotMapped() {
		fh 	 := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		verifyErrMsg(BedSheetNotFoundErr#, BsErrMsgs.fileHandler_fileNotMapped(`res/misc/quotes.txt`.toFile)) {
			fh.fromServerFile(`res/misc/quotes.txt`.toFile)
		}
	}
	
	Void testAssetFile() {
		fh  := makeFileHandler( [`/over-there/`:File(`doc/`)] )
		ass := fh.fromServerFile(`doc/pod.fdoc`.toFile)
		verifyEq(ass.clientUrl, `/over-there/pod.fdoc`)
	}

		
	private FileHandler makeFileHandler(Uri:File dirMappings) {
		bob := BeanFactory(FileHandlerImpl#)
		bob.add(dirMappings)
		bob.setByName("assetCache", AssetCacheMock())
//		bob.setByName("registry",   RegistryBuilder().build)
		return bob.create
	}
}

internal const class AssetCacheMock : AssetCache {
	override CachableAsset getOrAddOrUpdate(Uri key, |Uri->CachableAsset| valFunc) { valFunc(key) }
	override Void remove(Uri? asset) { }
	override Void clear() { }
	override Int size() { 0 }
	override Uri toClientUrl(Uri localUrl, CachableAsset asset) { localUrl }
}
