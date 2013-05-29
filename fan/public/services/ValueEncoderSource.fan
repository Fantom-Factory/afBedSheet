using afIoc::StrategyRegistry

** Holds a collection of `ValueEncoder`s.
const class ValueEncoderSource {
	
	private const StrategyRegistry valueEncoderStrategy
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	Str toClient(Type valType, Obj value) {
		try {
			return get(valType).toClient(value)
		} catch (Err cause) {
			throw ValueEncodingErr(BsMsgs.valueEncodingBuggered(value, Str#), cause)
		}
	}

	Obj toValue(Type valType, Str clientValue) {
		try {
			return get(valType).toValue(clientValue)
		} catch (Err cause) {
			throw ValueEncodingErr("Could not convert $clientValue to $valType.qname", cause)			
		}
	}

	private ValueEncoder get(Type valueType) {
		valueEncoderStrategy.findExactMatch(valueType)
	}
}
