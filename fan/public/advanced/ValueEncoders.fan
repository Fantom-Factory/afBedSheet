using afBeanUtils::BeanFactory

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
	** If no 'ValueEncoder' is found the value is [coerced]`afBeanUtils::TypeCoercer`.
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
		
		// give the val encs a chance to handle nulls
		valEnc := find(valType)
		if (valEnc != null)
			try {
				return valEnc.toClient(value)
			} catch (ReProcessErr reprocess) {
				throw reprocess
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(value, Str#), cause)
			}
		
		// don't bother with a TypeCoercer, just toStr it.
		// by default, represent null as an empty string
		return value?.toStr ?: Str.defVal
	}

	override Obj? toValue(Type valType, Str clientValue) {
		// check the basics first!
		if (valType.toNonNullable == Str#)
			return clientValue

		// give the val encs a chance to handle nulls
		valEnc := find(valType)
		if (valEnc != null) {
			value := null
			try {
				value = valEnc.toValue(clientValue)
			} catch (ReProcessErr reprocess) {
				throw reprocess
			} catch (Err cause) {
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
			}
			// a final null compatibility check
			if (value == null && !valType.isNullable)
				throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType))
			return value
		}

		// empty string values WILL ALWAYS DIE in the coercer, so treat them as null and create a default value
		if (clientValue.trim.isEmpty)
			try	return BeanFactory.defaultValue(valType)
		catch (Err cause)
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
		
		try	return typeCoercer.coerce(clientValue, valType) 
		catch (Err cause)
			throw ValueEncodingErr(BsErrMsgs.valueEncoding_buggered(clientValue, valType), cause)
	}

	override ValueEncoder? find(Type valueType) {
		valueEncoderLookup.findParent(valueType, false)
	}
}
