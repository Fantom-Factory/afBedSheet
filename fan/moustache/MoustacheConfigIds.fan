
** Config values as used by Moustache. 
** To change their value, override them in your 'AppModule'. Example:
** 
** pre>
** @Contribute { serviceType=ApplicationDefaults# } 
** static Void configureAppDefaults(MappedConfig conf) {
**   conf[MoustacheConfigIds.moustacheTemplateTimeout] = 1min
** }
** <pre
const mixin MoustacheConfigIds {

	** The time before the file system is checked for template updates.
	** Defaults to '10sec'
	static const Str moustacheTemplateTimeout		:= "afBedSheet.moustache.templateTimeout"

}
