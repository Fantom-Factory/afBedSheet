using afIoc::ConcurrentState
using afIoc::StrategyRegistry
using afIoc::TypeCoercer

** Holds a collection of `ValueEncoder`s.
** 
** pre>
**   @Contribute { serviceType=ValueEncoderSource# }
**   static Void contributeValueEncoders(MappedConfig conf) {
**     conf[MyEntity#] = conf.autobuild(MyEntityEncoder#)
**   }
** <pre
** 
** @uses a MappedConfig of 'Type':`ValueEncoder`s
const class ValueEncoders {
	private const ConcurrentState 	conState	:= ConcurrentState(ValueEncoderSourceState#)
	private const StrategyRegistry 	valueEncoderStrategy
	
	internal new make(Type:ValueEncoder valueEncoders) {
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
	** If no 'ValueEncoder' is found the value is [coerced]`afIoc::TypeCoercer`.
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
		
		if (getState() { it.typeCoercer.canCoerce(Str#, valType) } == false)
			throw ValueEncodingErr(BsMsgs.valueEncodingNotFound(valType))
		
		try {
			return getState() { it.typeCoercer.coerce(clientValue, valType) } 
		} catch (Err cause) {
			throw ValueEncodingErr(BsMsgs.valueEncodingBuggered(clientValue, valType), cause)
		}
	}

	private ValueEncoder? get(Type valueType) {
		valueEncoderStrategy.findBestFit(valueType, false)
	}

	private Obj? getState(|ValueEncoderSourceState -> Obj| state) {
		conState.getState(state)
	}
}

internal class ValueEncoderSourceState {
	TypeCoercer	typeCoercer	:= TypeCoercer()
}