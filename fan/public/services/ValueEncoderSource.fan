using afIoc::StrategyRegistry

const class ValueEncoderSource {
	
	private const StrategyRegistry valueEncoderStrategy
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	ValueEncoder getValueEncoder(Type valueType) {
		valueEncoderStrategy.findBestFit(valueType)
	}
}
