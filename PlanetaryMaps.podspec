Pod::Spec.new do |s|
  s.name             = 'PlanetaryMaps'
  s.version          = '1.0.1'
  s.summary          = 'iOS OpenGL Tiled Maps Viewer'

  s.description      = 'An iOS library that allows the developer to easily add a Google Earth style zoomable mapping view. It supports arbitrary zooming and panning and a clean API to draw lines and markers on the planet surface. You will need to provide URLs for map tiles that are in geodetic projection. Several Python and Bash scripts are provided that can be used to convert GeoTIFF and GeoPDF files to geodetic tiles that can be used with PlanetaryMaps.'

  s.homepage         = 'https://github.com/spietari/PlanetaryMaps'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Seppo Pietarinen' => 'seppo@unitedgalactic.com' }
  s.source           = { :git => 'https://github.com/spietari/PlanetaryMaps.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/pietarinenseppo'
  s.ios.deployment_target = '8.0'

  s.source_files = 'PlanetaryMaps/Classes/**/*'
  s.resource_bundles = {
    'PlanetaryMaps' => ['PlanetaryMaps/Assets/**/*']
  }

  s.frameworks = 'GLKit'

end