
internal class AppRun {
	
	static Void main(Str[] args) {
		Main().main("-proxy ${T_AppModule#.qname} 8079".split)

//		Main().main("${T_AppModule#.qname} 8079".split)
		
//		AppTest().setup
//		concurrent::Actor.sleep(Duration.maxVal)
	}
}
