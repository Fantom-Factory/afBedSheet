
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
	static const Str templateTimeout	:= "afBedSheet.moustache.templateTimeout"

	** When printing a `MoustacheErr`, this is the number of lines of code to print before and 
	** after the actual error. 
	** Defaults to '5'
	static const Str linesOfSrcCode		:= "afBedSheet.moustache.linesOfSrcCode"

}
