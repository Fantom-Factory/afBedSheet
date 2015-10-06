using afConcurrent
using afIoc

internal const class LocalProvider : DependencyProvider {

	static	private const Type[]				localTypes		:= [LocalRef#, LocalList#, LocalMap#]	
			private const ThreadLocalManager	localManager

	new make(ThreadLocalManager	localManager) {
		this.localManager = localManager 
	}

	override Bool canProvide(Scope scope, InjectionCtx ctx) {
		// IoC standards dictate that field injection should be denoted by a facet
		if (ctx.isFieldInjection && !ctx.field.hasFacet(Inject#))
			return false
		dependencyType := ctx.field?.type ?: ctx.funcParam?.type
		return localTypes.contains(dependencyType.toNonNullable) && ctx.targetType != null
	}
	
	override Obj? provide(Scope scope, InjectionCtx ctx) {
		type := (ctx.field?.type ?: ctx.funcParam?.type)?.toNonNullable
		name := ctx.targetType.qname.replace("::", ".")
		if (ctx.field != null)
			name += "." + ctx.field.name
		if (ctx.funcParam != null)
			name += "." + ctx.funcParam.name
		
		// let @Inject.id override the default name
		inject	:= (Inject?) ctx.field.facets.findType(Inject#).first
		if (inject?.id != null)
			name = inject.id 
		
		if (type == LocalRef#)
			return localManager.createRef(name)

		if (type == LocalList#) {
			listType := inject?.type
			if (listType == null)
				return localManager.createList(name)

			if (listType.params["L"] == null)
				throw IocErr(localProvider_typeNotList(ctx.field, listType))
			return LocalList(localManager.createName(name)) {
				it.valType = listType.params["V"]
			} 
		}

		if (type == LocalMap#) {
			mapType := inject?.type
			if (mapType == null)
				return localManager.createMap(name)

			if (mapType.params["M"] == null)
				throw IocErr(localProvider_typeNotMap(ctx.field, mapType))

			return LocalMap(localManager.createName(name)) {
				it.keyType = mapType.params["K"]
				it.valType = mapType.params["V"]
				if (it.keyType == Str#)
					it.caseInsensitive = true
				else
					it.ordered = true
			} 
		}

		throw Err("What's a {$type.qname}???")
	}
	
	static Str localProvider_typeNotList(Field field, Type type) {
		"@Inject { type=${type.signature}# } on field ${field.qname} should be a list type, e.g. @Inject { type=Str[]# }"
	}

	static Str localProvider_typeNotMap(Field field, Type type) {
		"@Inject { type=${type.signature}# } on field ${field.qname} should be a map type, e.g. @Inject { type=[Int:Str]# }"
	}
}
