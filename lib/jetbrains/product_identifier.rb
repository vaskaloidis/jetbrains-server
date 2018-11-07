module Jetbrains
  

  class ProductIdentifier
    JETBRAINS_PRODUCT_UUIDS = { # Extracted from IDEA's main jar - com.jetbrains.licenseServer.Products
      '49c202d4-ac56-452b-bb84-735056242fb3' => 'IDEA',
      'b27b2de6-cc3c-4e75-a0a6-d3aead9c2d8b' => 'RubyMine',
      '342e66b2-956c-4384-81da-f50365b990e9' => 'WebStorm',
      '0d85f2cc-b84f-44c7-b319-93997d080ac9' => 'PhpStorm',
      'e8d15448-eecd-440e-bbe9-1e5f754d781b' => 'PyCharm',
      '8a00c148-759c-4289-80ae-63fe83cb14f9' => 'AppCode',
      '94ed896e-599e-4e2c-8724-204935e593ff' => 'DataGrip',
      'cfc7082d-ae43-4978-a2a2-46feb1679405' => 'CLion',

      '5931f436-2506-415e-a0a9-27f50d7f62bf' => 'Resharper',
      '39365442-7F02-4765-AB93-770C04F400B7' => 'ReSharper C++',
      'fdf9f05f-d8fe-44b1-9721-4455e35ea49f' => 'DotTrace',
      'DD8D40C7-866B-4204-9D56-9E620CD76A4D' => 'DotMemory',
      '59BB7CF0-D203-4E54-9A5F-04FBB1AEBCD4' => 'DotCover'
    }.freeze

    def self.get_product_name_for_family_id(uuid)
      JETBRAINS_PRODUCT_UUIDS[uuid] || format('unknown product (%s)', uuid)
    end
  end
end