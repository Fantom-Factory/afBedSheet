using concurrent
using afConcurrent

** (Service) -
** Use to create 'LocalRef' / 'LocalList' / 'LocalMap' instances whose contents can be *cleaned* up. 
** Erm, I mean deleted! 
**  
** This is particularly important in the context of web applications where resources need to be 
** *cleaned* up at the end of a web request / thread. 
** 
** Then when 'cleanUpThread()' is called, all thread local data created by this manager will be
** deleted from 'Actor.locals' 
**
** LocalXXX Injection
** ******************
** IoC defines a 'DependencyProvider' that injects 'LocalXXX' instances directly into your class.
** Where possible, the field name is used as the *local* name. 
** 
** pre>
** syntax: fantom
** const class Example {
**     @Inject const LocalMap localMap
** 
**     new make(|This|in) { in(this) }
** }
** <pre
** 
** '@Inject.type' may be used to declare the underlying parameters of the 'LocalList / LocalMap':
** 
** pre>
** syntax: fantom
** const class Example {
**     @Inject { type=Str[]# }
**     const LocalList localList
** 
**     @Inject { type=[Str:Slot?]# }
**     const LocalMap localMap
** 
**     new make(|This|in) { in(this) }
** }
** <pre
** 
** If '@Inject.type' is used with a 'LocalMap', then if the key is a 'Str' the map will be 
** case-insensitive, otherwise it will be ordered.  
** 
** @since 1.6.0
const mixin ThreadLocalManager {

	** Creates a `afConcurrent::LocalRef` with the given default function.
	abstract LocalRef createRef(Str name, |->Obj?|? defFunc := null)

	** Creates a `afConcurrent::LocalList` with the given name.
	abstract LocalList createList(Str name)

	** Creates a `afConcurrent::LocalMap` with the given name.
	abstract LocalMap createMap(Str name)

	** Creates a qualified name unique to this 'ThreadLocalManager' that when used to create a 
	** Local Refs, List or Map, ensures it is cleanup up with all the others.  
	abstract Str createName(Str name)

	** Returns all (fully qualified) keys in the current thread associated / used with this manager. 
	abstract Str[] keys() 
	
	** Add a handler to be called on thread clean up. New handlers have to be added for each thread.
	abstract Void addCleanUpHandler(|->| handler)
	
	** Removes all values in the current thread associated / used with this manager.
	abstract Void cleanUpThread()
}


internal const class ThreadLocalManagerImpl : ThreadLocalManager {
	static	
	private const AtomicInt	counter	:= AtomicInt(0)
	private const LocalList	cleanUpHandlers
	
	const Str prefix
	
	new make() {
		this.prefix = createPrefix
		this.cleanUpHandlers = createList("ThreadLocalManager.cleanupHandlers")
	}

	override LocalRef createRef(Str name, |->Obj?|? defFunc := null) {
		LocalRef(createName(name), defFunc)
	}

	override LocalList createList(Str name) {
		LocalList(createName(name))
	}

	override LocalMap createMap(Str name) {
		LocalMap(createName(name))
	}

	override Str createName(Str name) {
		"${prefix}.\${id}.${name}"
	}
	
	override Str[] keys() {
		Actor.locals.keys
			.findAll { it.startsWith(prefix) }
			.sort
	}
	
	override Void addCleanUpHandler(|->| handler) {
		cleanUpHandlers.add(handler)
	}
	
	override Void cleanUpThread() {
		cleanUpHandlers.each | |->| handler| { handler.call }
		keys.each { Actor.locals.remove(it) }
	}

	// ---- Helper Methods ------------------------------------------------------------------------
	
	private Str createPrefix() {
		count 	:= counter.incrementAndGet
		padded	:= count.toStr.padl(2, '0')
		prefix 	:= "TLM-${padded}"
		return prefix
	}
}
