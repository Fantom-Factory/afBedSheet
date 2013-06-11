
internal class ReflectUtils {
	private new make() { }

	static Field? findField(Type type, Str fieldName, Type fieldType) {
		// 'fields()' returns inherited slots, 'field(name)' does not
		return type.fields.find |field| {
			if (field.name != fieldName) 
				return false
			if (!field.type.fits(fieldType))
				return false				
			return true 
		}
	}
	
	static Method? findCtor(Type type, Str ctorName, Type[] params := [,]) {
		// 'methods()' returns inherited slots, 'method(name)' does not
		return type.methods.find |method| {
			if (!method.isCtor) 
				return false
			if (method.name != ctorName) 
				return false
			if (!paramTypesFitMethodSignature(params, method))
				return false				
			return true 
		}
	}

	static Method? findMethod(Type type, Str name, Type[] params := [,], Bool isStatic := false, Type? returnType := null) {
		// 'methods()' returns inherited slots, 'method(name)' does not
		return type.methods.find |method| {
			if (method.isCtor) 
				return false
			if (method.name != name) 
				return false
			if (method.isStatic != isStatic) 
				return false
			if (returnType != null && !method.returns.fits(returnType))
				return false
			if (!paramTypesFitMethodSignature(params, method))
				return false				
			return true 
		}
	}

	static Bool paramTypesFitMethodSignature(Type[] params, Method method) {
		return method.params.all |methodParam, i->Bool| {
			if (i >= params.size)
				return methodParam.hasDefault
			if (!params[i].fits(methodParam.type))
				return false
			return true
		}
	}
}
