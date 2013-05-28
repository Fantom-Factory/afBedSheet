using afIoc::StrategyRegistry

** Holds a collection of `ValueEncoder`s.
const class ValueEncoderSource {
	
	private const StrategyRegistry valueEncoderStrategy
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	ValueEncoder getValueEncoder(Type valueType) {
		valueEncoderStrategy.findExactMatch(valueType)
	}
}
