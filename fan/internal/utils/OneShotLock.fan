
internal class OneShotLock {

	private Str 	because
	private Bool	lockFlag

	new make(Str because) {
		this.because = because
	}

	Void lock() {
		check	// you can't lock twice!
		lockFlag = true
	}
	
	Bool isLocked() {
		lockFlag
	}

	public Void check() {
		if (lockFlag)
			throw BedSheetErr(BsErrMsgs.oneShotLockViolation(because))
	}

	override Str toStr() {
		(lockFlag ? "" : "(un)") + "locked"
	}
}
