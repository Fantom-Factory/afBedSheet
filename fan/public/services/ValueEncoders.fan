using afIoc::ConcurrentState
using afIoc::StrategyRegistry
using afIoc::TypeCoercer

** Holds a list of `ValueEncoder`s.
** 
** pre>
**   @Contribute { serviceType=ValueEncoders# }
**   static Void contributeValueEncoders(MappedConfig conf) {
**     conf[MyEntity#] = conf.autobuild(MyEntityEncoder#)
**   }
** <pre
** 
** @uses a MappedConfig of 'Type:ValueEncoder'
const mixin ValueEncoders {
	
	** Converts the given 'value' to Str via a contributed `ValueEncoder`. If no 'ValueEncoder' is 
	** found, 'toStr()' is used. 
	abstract Str toClient(Type valType, Obj value)
	
	** Converts the given 'clientValue' into the given 'valType' via a contributed `ValueEncoder`. 
	** If no 'ValueEncoder' is found the value is [coerced]`afIoc::TypeCoercer`.
	abstract Obj toValue(Type valType, Str clientValue)
}

internal const class ValueEncodersImpl : ValueEncoders {
	private const ConcurrentState 	conState	:= ConcurrentState(ValueEncodersState#)
	private const StrategyRegistry 	valueEncoderStrategy
	
	internal new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderStrategy = StrategyRegistry(valueEncoders)
	}
	
	override Str toClient(Type valType, Obj value) {
		// check the basics first!
		if (value is Str)
			return value
		
		valEnc := get(valType)
		if (valEnc != null)
			try {
				return valEnc.toClient(value)
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncodingBuggered(value, Str#), cause)
			}
		
		return value.toStr
	}

	override Obj toValue(Type valType, Str clientValue) {
		// check the basics first!
		if (valType.fits(Str#))
			return clientValue

		valEnc := get(valType)
		if (valEnc != null)
			try {
				return get(valType).toValue(clientValue)
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncodingBuggered(clientValue, valType), cause)
			}
		
		if (getState() { it.typeCoercer.canCoerce(Str#, valType) } == false)
			throw ValueEncodingErr(BsErrMsgs.valueEncodingNotFound(valType))
		
		try {
			return getState() { it.typeCoercer.coerce(clientValue, valType) } 
		} catch (Err cause) {
			throw ValueEncodingErr(BsErrMsgs.valueEncodingBuggered(clientValue, valType), cause)
		}
	}

	private ValueEncoder? get(Type valueType) {
		valueEncoderStrategy.findBestFit(valueType, false)
	}

	private Obj? getState(|ValueEncodersState -> Obj| state) {
		conState.getState(state)
	}
}

internal class ValueEncodersState {
	TypeCoercer	typeCoercer	:= TypeCoercer()
}
