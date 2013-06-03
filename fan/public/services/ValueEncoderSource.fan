using afIoc::StrategyRegistry

** Holds a collection of `ValueEncoder`s.
** 
** BedSheet ships with default ValueEncoders for: 
**  - Str
**  - Int 
** 
** pre>
**   @Contribute { serviceType=ValueEncoderSource# }
**   static Void contributeValueEncoders(MappedConfig config) {
**     config.addMapped(MyEntity#, config.autobuild(MyEntityEncoder#))
**   }
** <pre
** 
** @uses a 'MappedConfig' of 'Type' to `ValueEncoder`s
const class ValueEncoderSource {
	
	private const StrategyRegistry valueEncoderStrategy
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	** Converts the given 'value' to Str via a contributed `ValueEncoder`. If no 'ValueEncoder' is 
	** found, 'toStr()' is used. 
	Str toClient(Type valType, Obj value) {
		// check the basics first!
		if (value is Str)
			return value
		
		valEnc := get(valType)
		if (valEnc != null)
			try {
				return valEnc.toClient(value)
			} catch (Err cause) {
				throw ValueEncodingErr(BsMsgs.valueEncodingBuggered(value, Str#), cause)
			}
		
		return value.toStr
	}

	** Converts the given 'clientValue' into the given 'valType' via a contributed `ValueEncoder`. 
	** If no 'ValueEncoder' is found, this looks for a suitable static factory 'fromStr()' method
	** on the type.
	Obj toValue(Type valType, Str clientValue) {
		// check the basics first!
		if (valType.fits(Str#))
			return clientValue

		valEnc := get(valType)
		if (valEnc != null)
			try {
				return get(valType).toValue(clientValue)
			} catch (Err cause) {
				throw ValueEncodingErr(BsMsgs.valueEncodingBuggered(clientValue, valType), cause)
			}
		
		// see http://fantom.org/sidewalk/topic/2154
		fromStr := ReflectUtils.findCtor(valType, "fromStr", [Str#])
		if (fromStr == null)
			fromStr = ReflectUtils.findMethod(valType, "fromStr", [Str#], true)
		if (fromStr == null)
			throw ValueEncodingErr(BsMsgs.valueEncodingNotFound(valType))
		
		try {
			return fromStr.call(clientValue) 
		} catch (Err cause) {
			throw ValueEncodingErr(BsMsgs.valueEncodingBuggered(clientValue, valType), cause)
		}
	}

	private ValueEncoder? get(Type valueType) {
		valueEncoderStrategy.findExactMatch(valueType, false)
	}
}
