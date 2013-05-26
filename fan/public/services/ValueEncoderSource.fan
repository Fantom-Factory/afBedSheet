
const class ValueEncoderSource {
	
	private const Type:ValueEncoder valueEncoders
	
	new make(Type:ValueEncoder valueEncoders) {
		this.valueEncoders = valueEncoders
	}
	
	// TODO: use cached adaprter pattern - see ModuleImpl.serviceDefsByType
	ValueEncoder getValueEncoder(Type valueType) {
		valueEncoders.find |encoder, encoderType| {
			valueType.fits(encoderType)
        }
		// TODO: throw better Err if not found
	}

}
