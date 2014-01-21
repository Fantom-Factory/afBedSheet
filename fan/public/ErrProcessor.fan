
** Implement to define an 'ErrProcessor'.
** 
** 'ErrProcessors' process Errs thrown from request handler methods. They typically generate and return err pages to 
** the client. They may also log details, raise alerts and send emails.
** 
** 'ErrProcessors' are mapped to a specific 'Err'. When an 'Err' is raised, the processor with the closest matching Err 
** type is called to handle it.
** 
** If no matching processor can be found, a default processor is used. You can override the default processor by 
** setting it in 'ApplicationDefaults':
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureApplicationDefaults(MappedConfig conf) {
**   conf[BedSheetConfigIds.defaultErrProcessor] = MyStatusPage()
** }
** <pre
**
** If you contribute an 'ErrHandler' with the type 'Err' then this is effectively a *catch all* processor (similar to 
** the default processor.) 
** 
** IOC Configuration
** =================
** Instances of 'ErrProcessor' should be contributed to the 'ErrProcessors' service. 
** They are added to a 'MappedConfig' whose key should be a 'Type', a subclass of 'Err' (or a mixin).   
** 
** For example, in your 'AppModule' class:
** 
** pre>
** @Contribute { serviceType=ErrProcessors# }
** static Void contributeErrProcessors(MappedConfig config) {
**     config[Err#] = CatchAllErrHandler()
** }
** <pre
** 
** @see `BedSheetConfigIds.defaultErrProcessor` 
const mixin ErrProcessor {
	
	** Returns a response obj for further processing (such as a `Text`) or 'true' if no 
	** more request processing is required.
	abstract Obj process(Err err)
	
}
