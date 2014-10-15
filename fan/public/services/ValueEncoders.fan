
** (Service) - Contribute your 'ValueEncoder' classes to this.
** 
** @uses a Configuration of 'Type:ValueEncoder' where 'Type' is what the 'ValueEncoder', um, encodes!
@NoDoc	// don't overwhelm the masses!
const mixin ValueEncoders {
	
	** Converts the given 'value' to Str via a contributed `ValueEncoder`. If no 'ValueEncoder' is 
	** found, 'toStr()' is used. 
	** 
	** 'valType' is NOT 'Str#'!!! But rather the Type of the Obj that is being converted. 
	** Required to ensure the correct 'ValueEncoder' is used, and to convert 'null' to default instances.
	abstract Str? toClient(Type valType, Obj? value)
	
	** Converts the given 'clientValue' into the given 'valType' via a contributed `ValueEncoder`. 
	** If no 'ValueEncoder' is found the value is [coerced]`afIoc::TypeCoercer`.
	abstract Obj? toValue(Type valType, Str? clientValue)
}

internal const class ValueEncodersImpl : ValueEncoders {
	private const CachingTypeCoercer	typeCoercer	:= CachingTypeCoercer()
	private const CachingTypeLookup		valueEncoderLookup
	
	internal new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderLookup = CachingTypeLookup(valueEncoders)
	}
	
	override Str? toClient(Type valType, Obj? value) {
		// check the basics first!
		if (value is Str)
			return value
		
		valEnc := get(valType)
		if (valEnc != null)
			try {
				return valEnc.toClient(value)
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(value, Str#), cause)
			}
		
		return value?.toStr
	}

	override Obj? toValue(Type valType, Str? clientValue) {
		// check the basics first!
		if (valType.fits(Str#))
			return clientValue

		// give the val encs a chance to handle nulls
		valEnc := get(valType)
		if (valEnc != null)
			try {
				return get(valType).toValue(clientValue)
			} catch (ReProcessErr reprocess) {
				throw reprocess
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
			}
		
		if (clientValue == null)
			return null
		
		if (!typeCoercer.canCoerce(Str#, valType))
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_notFound(valType))
		
		try {
			return typeCoercer.coerce(clientValue, valType) 
		} catch (Err cause) {
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
		}
	}

	private ValueEncoder? get(Type valueType) {
		valueEncoderLookup.findParent(valueType, false)
	}
}
