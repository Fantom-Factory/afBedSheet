
const mixin HttpPipeline {

	abstract Bool service() 

}

const mixin HttpPipelineFilter {

	abstract Bool service(HttpPipeline handler) 

}
