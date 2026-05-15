/// Domain type configuration for PneumaGe projects
/// 
/// Each project can specify a domain type (agriculture, arctic, maritime, volcanology)
/// which determines what additional metadata fields are collected during measurements.

class DomainConfig {
  /// Available domain types
  static const String none = 'NONE';
  static const String agriculture = 'AGRICULTURE';
  static const String arctic = 'ARCTIC';
  static const String maritime = 'MARITIME';
  static const String volcanology = 'VOLCANOLOGY';

  /// All domain types for dropdowns
  static const List<String> allDomains = [
    none,
    agriculture,
    arctic,
    maritime,
    volcanology,
  ];

  /// Display names for domains
  static const Map<String, String> domainDisplayNames = {
    none: 'None',
    agriculture: 'Agriculture',
    arctic: 'Arctic',
    maritime: 'Maritime',
    volcanology: 'Volcanology',
  };

  /// Agriculture field definitions
  static const List<DomainField> agricultureFields = [
    DomainField(
      key: 'cropType',
      label: 'Crop Type',
      hint: 'e.g. Corn, Wheat, Soybean',
      required: true,
    ),
    DomainField(
      key: 'growthStage',
      label: 'Growth Stage',
      hint: 'e.g. Vegetative, Flowering, Harvest',
      required: false,
    ),
    DomainField(
      key: 'fertilizerApplication',
      label: 'Fertilizer Application',
      hint: 'Type and date of last application',
      required: false,
    ),
    DomainField(
      key: 'irrigationStatus',
      label: 'Irrigation Status',
      hint: 'e.g. Irrigated, Rainfed',
      required: false,
    ),
    DomainField(
      key: 'soilType',
      label: 'Soil Type',
      hint: 'e.g. Clay, Loam, Sandy',
      required: false,
    ),
  ];

  /// Arctic field definitions
  static const List<DomainField> arcticFields = [
    DomainField(
      key: 'permafrostDepth',
      label: 'Permafrost Depth (cm)',
      hint: 'Depth to permafrost layer',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'activeLayerThickness',
      label: 'Active Layer Thickness (cm)',
      hint: 'Thickness of seasonally thawed layer',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'snowCoverDepth',
      label: 'Snow Cover Depth (cm)',
      hint: 'Current snow depth',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'thawStatus',
      label: 'Thaw Status',
      hint: 'e.g. Frozen, Thawing, Thawed',
      required: false,
    ),
  ];

  /// Maritime field definitions
  static const List<DomainField> maritimeFields = [
    DomainField(
      key: 'waterDepth',
      label: 'Water Depth (m)',
      hint: 'Depth at measurement location',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'salinity',
      label: 'Salinity (PSU)',
      hint: 'Practical Salinity Units',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'currentSpeed',
      label: 'Current Speed (m/s)',
      hint: 'Water current velocity',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'waveHeight',
      label: 'Wave Height (m)',
      hint: 'Significant wave height',
      required: false,
      isNumeric: true,
    ),
  ];

  /// Volcanology field definitions
  static const List<DomainField> volcanologyFields = [
    DomainField(
      key: 'fumaroleActivity',
      label: 'Fumarole Activity',
      hint: 'e.g. Active, Dormant, Extinct',
      required: false,
    ),
    DomainField(
      key: 'groundTemperature',
      label: 'Ground Temperature (°C)',
      hint: 'Surface temperature at site',
      required: false,
      isNumeric: true,
    ),
    DomainField(
      key: 'seismicActivityLevel',
      label: 'Seismic Activity Level',
      hint: 'e.g. None, Low, Moderate, High',
      required: false,
    ),
  ];

  /// Get field definitions for a specific domain
  static List<DomainField> getFieldsForDomain(String domain) {
    switch (domain) {
      case agriculture:
        return agricultureFields;
      case arctic:
        return arcticFields;
      case maritime:
        return maritimeFields;
      case volcanology:
        return volcanologyFields;
      default:
        return [];
    }
  }

  /// Check if a domain has fields
  static bool hasFields(String domain) {
    return domain != none && getFieldsForDomain(domain).isNotEmpty;
  }
}

/// Domain field definition
class DomainField {
  final String key;
  final String label;
  final String hint;
  final bool required;
  final bool isNumeric;

  const DomainField({
    required this.key,
    required this.label,
    required this.hint,
    this.required = false,
    this.isNumeric = false,
  });
}
