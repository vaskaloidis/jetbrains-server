module Jetbrains
	class LicenseSigner
    # CrackAttackz key was being weird with everything but python-rsa so I decompiled the original server and found that the key is stored as three bigints in com.jetbrains.ls.floating.FloatingPrivateKeysKt:
    #    private static final String MODULUS = "9616540267013058477253762977293425063379243458473593816900454019721117570003248808113992652836857529658675570356835067184715201230519907361653795328462699";
    #    private static final String EXPONENT = "65537";
    #    private static final String PRIVATE_EXPONENT = "4802033916387221748426181350914821072434641827090144975386182740274856853318276518446521844642275539818092186650425384826827514552122318308590929813048801";
    # I then used https://github.com/ius/rsatool to derive this key from those values (protip for people who can't crypto: modulus = n, private_exponent = d)
    # His key, I think, doesn't include p and q which caused it to fail when used with pretty much everything, whereas rsatool derives those for us <img src="images/smileys/Smile.png" />
    # This is a simple multiline string to make it easy to copy-paste
    PRIVATE_KEY = "-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBALecq3BwAI4YJZwhJ+snnDFj3lF3DMqNPorV6y5ZKXCiCMqj8OeOmxk4YZW9aaV9
ckl/zlAOI0mpB3pDT+Xlj2sCAwEAAQJAW6/aVD05qbsZHMvZuS2Aa5FpNNj0BDlf38hOtkhDzz/h
kYb+EBYLLvldhgsD0OvRNy8yhz7EjaUqLCB0juIN4QIhAOeCQp+NXxfBmfdG/S+XbRUAdv8iHBl+
F6O2wr5fA2jzAiEAywlDfGIl6acnakPrmJE0IL8qvuO3FtsHBrpkUuOnXakCIQCqdr+XvADI/UTh
TuQepuErFayJMBSAsNe3NFsw0cUxAQIgGA5n7ZPfdBi3BdM4VeJWb87WrLlkVxPqeDSbcGrCyMkC
IFSs5JyXvFTreWt7IQjDssrKDRIPmALdNjvfETwlNJyY
-----END RSA PRIVATE KEY-----".freeze
    SIGNATURE_ALGORITHM = OpenSSL::Digest::MD5

    attr_reader :private_key

    def initialize
      @private_key = OpenSSL::PKey::RSA.new(PRIVATE_KEY)
    end

    def sign(message)
      to_hex(@private_key.sign(SIGNATURE_ALGORITHM.new, message).bytes)
    end

    def verify(signature, message)
      @private_key.verify(SIGNATURE_ALGORITHM.new, from_hex(signature), message)
    end

    # To-Hex
    # The original server uses this weird hex encoding algorithm (as does CrackAttackz since s/he basically ported jetprofile.licenseService.Signer), but this is less confusing
    def to_hex(bytes)
      bytes.map { |b| format('%02x', b) }.join
    end

    def from_hex(str)
      [str].pack('H*')
    end
  end
end