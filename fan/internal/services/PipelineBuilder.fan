using afIoc
using afPlastic::PlasticCompiler
using afPlastic::IocClassModel

** (Service) -
** In this pattern, also know as a *filter chain*, a service endpoint (known as the terminator) is
** at the end of a pipeline of filters. 
** 
** Each method invocation on the returned service is routed through the filters before the 
** terminator is called. Each filter has an opportunity to modify method arguments and the return 
** value or shortcut the call completely.

const mixin PipelineBuilder {
	
	abstract Obj build(Type pipelineType, Type filterType, Obj[] filters, Obj terminator)
}

internal const class PipelineBuilderImpl : PipelineBuilder {
	
	private const ConcurrentCache typeCache	:= ConcurrentCache()

	@Inject	
	private const PlasticCompiler plasticCompiler

	private const Method[]	objMethods	:= Obj#.methods
	
	new make(|This|in) { in(this) }
	
	override Obj build(Type pipelineType, Type filterType, Obj[] filters, Obj terminator) {

		if (!terminator.typeof.fits(pipelineType))
			throw BedSheetErr(BsErrMsgs.pipelineTerminatorMustExtendPipeline(pipelineType, terminator.typeof))
		filters.each |filter| { 
			if (!filter.typeof.fits(filterType))
				throw BedSheetErr(BsErrMsgs.pipelineFilterMustExtendFilter(filterType, filter.typeof))
		}		
		
		bridgeType	:= buildBridgeType(pipelineType, filterType)
		
		nextField 	:= bridgeType.field("next")
		handField 	:= bridgeType.field("handler")

		pipeline := filters.reverse.reduce(terminator) |toWrap, filter| {
			makePlan	:= Field:Obj?[nextField:filter, handField:toWrap]
			ctorFunc	:= Field.makeSetFunc(makePlan)
			bridge		:= bridgeType.make([ctorFunc])
			return bridge
		}

		return pipeline
	}
	
	private Type buildBridgeType(Type pipelineType, Type filterType) {
		if (typeCache.containsKey(key(pipelineType, filterType)))
			return typeCache[key(pipelineType, filterType)]
		
		pipelineMethods := pipelineType.methods.rw
			.removeAll(objMethods)
			.findAll { it.isAbstract || it.isVirtual }
		
		// have the public checks last so we can test all other scenarios with internal test types
		if (!pipelineType.isMixin)
			throw BedSheetErr(BsErrMsgs.pipelineTypeMustBeMixin("Pipeline", pipelineType))
		if (!filterType.isMixin)
			throw BedSheetErr(BsErrMsgs.pipelineTypeMustBeMixin("Pipeline Filter", filterType))
		if (!pipelineType.fields.isEmpty)
			throw BedSheetErr(BsErrMsgs.pipelineTypeMustNotDeclareFields(pipelineType))
		pipelineMethods.each |method| {
			fMeth := ReflectUtils.findMethod(filterType, method.name, method.params.map { it.type }.add(pipelineType), false, method.returns)
			if (fMeth == null) {
				sig := method.signature[0..-2] + ", ${pipelineType.qname} handler)"
				throw BedSheetErr(BsErrMsgs.pipelineFilterMustDeclareMethod(filterType, sig))
			}
		}
		if (!pipelineType.isPublic)
			throw BedSheetErr(BsErrMsgs.pipelineTypeMustBePublic("Pipeline", pipelineType))
		if (!filterType.isPublic)
			throw BedSheetErr(BsErrMsgs.pipelineTypeMustBePublic("Pipeline Filter", filterType))
		
		model := IocClassModel("${pipelineType.name}Bridge", pipelineType.isConst)
		model.extendMixin(pipelineType)
		model.addField(filterType, "next")
		model.addField(pipelineType, "handler")

		pipelineMethods.each |method| {
			args := method.params.map { it.name }.add("handler").join(", ")
			body := "next.${method.name}(${args})"
			model.overrideMethod(method, body)
		}

		code 		:= model.toFantomCode
		podName		:= plasticCompiler.generatePodName
		pod 		:= plasticCompiler.compileCode(code, podName)
		bridgeType 	:= pod.type(model.className)
		
		typeCache[key(pipelineType, filterType)] = bridgeType
		
		return bridgeType
	}
	
	private Str key(Type pipelineType, Type filterType) {
		"${pipelineType.qname}-${filterType.qname}"
	}
}

// Example generated Bridge class
//const class HttpHandlerBridge : HttpHandler {
//	private const HttpFilter next
//	private const HttpHandler handler
//	
//	new make(HttpFilter next, HttpHandler handler) {
//		this.next = next
//		this.handler = handler
//	}
//	
//	override Bool service(HttpRequest? request, HttpResponse? response) {
//		return next.service(request, response, handler)
//	}
//}



