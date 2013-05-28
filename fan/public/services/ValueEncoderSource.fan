using afIoc::StrategyRegistry

** Holds a collection of `ValueEncoder`s.
const class ValueEncoderSource {
	
	private const StrategyRegistry valueEncoderStrategy
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	Str toClient(Type valType, Obj value) {
		get(valType).toClient(value)
	}

	Obj toValue(Type valType, Str clientValue) {
		get(valType).toValue(clientValue)
	}
	
	private ValueEncoder get(Type valueType) {
		valueEncoderStrategy.findExactMatch(valueType)
	}
}
