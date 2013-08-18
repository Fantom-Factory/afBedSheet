using afIoc::Contribute
using afIoc::OrderedConfig
using afIoc::MappedConfig
using afIoc::ServiceBinder
using web::WebOutStream

internal class MoustacheModule {
	
	static Void bind(ServiceBinder binder) {
		binder.bindImpl(MoustacheTemplates#).withoutProxy		// has default method args		
	}
	
	@Contribute { serviceType=ErrPrinterHtml# }
	static Void contributeErrPrinterHtml(OrderedConfig config) {
		printer := (MoustacheErrPrinter) config.autobuild(MoustacheErrPrinter#)		
		config.addOrdered("Moustache", |WebOutStream out, Err? err| { printer.printHtml(out, err) }, ["Before: StackTrace", "After: IocOperationTrace"])
	}

	@Contribute { serviceType=ErrPrinterStr# }
	static Void contributeErrPrinterStr(OrderedConfig config) {
		printer := (MoustacheErrPrinter) config.autobuild(MoustacheErrPrinter#)
		config.addOrdered("Moustache", |StrBuf out, Err? err| { printer.printStr(out, err) }, ["Before: StackTrace", "After: IocOperationTrace"])
	}

	@Contribute { serviceType=FactoryDefaults# }
	static Void contributeFactoryDefaults(MappedConfig config) {
		config[MoustacheConfigIds.templateTimeout]		= 10sec
		config[MoustacheConfigIds.linesOfSrcCode]		= 5
	}
}
