
** Use with '@Inject' to inject config values into your classes. Example:
** 
** @Inject @Config { "afBedSheet.gzip.threshold" }
** private Int gzipThreshold
** 
** @see `ConfigIds` for a list config values provided by BedSheet.
facet class Config {
	const Str? id := null
}
