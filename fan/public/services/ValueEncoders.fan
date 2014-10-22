
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
	abstract Str toClient(Type valType, Obj? value)
	
	** Converts the given 'clientValue' into the given 'valType' via a contributed `ValueEncoder`. 
	** If no 'ValueEncoder' is found the value is [coerced]`afIoc::TypeCoercer`.
	abstract Obj? toValue(Type valType, Str clientValue)

	** Finds a 'ValueEncoder' for the given type. Returns 'null' if none found.
	abstract ValueEncoder? find(Type valType)
}

internal const class ValueEncodersImpl : ValueEncoders {
	private const CachingTypeCoercer	typeCoercer	:= CachingTypeCoercer()
	private const CachingTypeLookup		valueEncoderLookup
	
	internal new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoderLookup = CachingTypeLookup(valueEncoders)
	}
	
	override Str toClient(Type valType, Obj? value) {
		// check the basics first!
		if (value is Str)
			return value
		
		valEnc := find(valType)
		if (valEnc != null)
			try {
				return valEnc.toClient(value)
			} catch (ReProcessErr reprocess) {
				throw reprocess
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(value, Str#), cause)
			}
		
		// represent null as an empty string
		return value?.toStr ?: Str.defVal
	}

	override Obj? toValue(Type valType, Str clientValue) {
		// check the basics first!
		if (valType.fits(Str#))
			return clientValue

		// give the val encs a chance to handle nulls
		valEnc := find(valType)
		if (valEnc != null)
			try {
				return valEnc.toValue(clientValue)
			} catch (ReProcessErr reprocess) {
				throw reprocess
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
			}

		// empty string values WILL ALWAYS DIE in the coercer, so treat them as nulls and give 
		// them a fighting chance - i.e. they're okay if the valType is nullable
		nullableValue := clientValue.isEmpty ? null : clientValue 
		
		if (!typeCoercer.canCoerce(Str#, valType))
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_notFound(valType))
		
		try {
			return typeCoercer.coerce(nullableValue, valType) 
		} catch (Err cause) {
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(nullableValue, valType), cause)
		}
	}

	override ValueEncoder? find(Type valueType) {
		valueEncoderLookup.findParent(valueType, false)
	}
}
