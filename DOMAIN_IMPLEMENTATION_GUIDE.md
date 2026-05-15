# Domain-Specific Metadata Implementation Guide

## Overview

PneumaGe now supports domain-specific metadata at the project level. When creating a new project, users can select a domain type (Agriculture, Arctic, Maritime, or Volcanology) and provide domain-specific information that will be automatically included in all measurements recorded under that project.

## Architecture

### Project Model
The `Project` model has been extended with two new fields:
- `domain` (String): The domain type (NONE, AGRICULTURE, ARCTIC, MARITIME, VOLCANOLOGY)
- `domainMetadata` (Map<String, dynamic>): Key-value pairs of domain-specific data

These fields are persisted in Hive (HiveField indices 10 and 11).

### Domain Configuration
A new `DomainConfig` class in `lib/config/domain_config.dart` defines:
- Available domain types
- Domain display names for UI
- Field definitions for each domain (label, key, hint, required, isNumeric)
- Helper methods to retrieve fields for a specific domain

### User Flow

1. **Project Creation**
   - User opens Files panel and clicks "Create New Project"
   - Enters project name and filename prefix
   - Selects domain type from dropdown
   - If domain selected (not "None"), conditional form fields appear
   - User fills in domain-specific metadata
   - Validation ensures required fields are completed
   - Project is created with domain information

2. **Measurement Recording**
   - When recording a measurement, the app reads the current project's domain and domainMetadata
   - This information is passed to `PneumaGeRecordFactory.createLiveMeasurement()`
   - The factory method populates the `SiteContext.activeDomain` and `SiteContext.domainSpecifics` fields
   - Domain metadata becomes part of the PneumaGeRecord and is saved with the measurement

3. **Data Export**
   - Domain metadata is included in JSON/CSV exports as part of the measurement data
   - Follows PneumaGe Master Schema v1.9.0 structure

## Domain Field Definitions

### Agriculture
- **cropType** (required): e.g. Corn, Wheat, Soybean
- **growthStage**: e.g. Vegetative, Flowering, Harvest
- **fertilizerApplication**: Type and date of last application
- **irrigationStatus**: e.g. Irrigated, Rainfed
- **soilType**: e.g. Clay, Loam, Sandy

### Arctic
- **permafrostDepth** (numeric): Depth to permafrost layer (cm)
- **activeLayerThickness** (numeric): Thickness of seasonally thawed layer (cm)
- **snowCoverDepth** (numeric): Current snow depth (cm)
- **thawStatus**: e.g. Frozen, Thawing, Thawed

### Maritime
- **waterDepth** (numeric): Depth at measurement location (m)
- **salinity** (numeric): Practical Salinity Units (PSU)
- **currentSpeed** (numeric): Water current velocity (m/s)
- **waveHeight** (numeric): Significant wave height (m)

### Volcanology
- **fumaroleActivity**: e.g. Active, Dormant, Extinct
- **groundTemperature** (numeric): Surface temperature at site (°C)
- **seismicActivityLevel**: e.g. None, Low, Moderate, High

## Implementation Details

### Files Modified

1. **lib/models/project.dart**
   - Added `domain` and `domainMetadata` fields with Hive annotations
   - Updated `copyWith`, `toJson`, `fromJson` methods

2. **lib/models/project.g.dart**
   - Regenerated Hive adapters to include new fields

3. **lib/config/domain_config.dart** (NEW)
   - Domain type constants
   - Field definitions for each domain
   - Helper methods for field retrieval

4. **lib/widgets/panels/files_panel.dart**
   - Updated `_CreateProjectBottomSheet` to include domain dropdown
   - Added conditional rendering of domain-specific form fields
   - Implemented validation for required fields
   - Collect and pass domain metadata to project creation

5. **lib/providers/project_provider.dart**
   - Added `domain` and `domainMetadata` parameters to `createProject()`

6. **lib/services/project_service.dart**
   - Added `domain` and `domainMetadata` parameters to `createProject()`
   - Pass values to Project constructor

7. **lib/models/measurement.dart**
   - Added `activeDomain` and `domainMetadata` parameters to `createLiveMeasurement()`
   - Factory method now populates `SiteContext.activeDomain` and `SiteContext.domainSpecifics`

8. **lib/screens/home_screen.dart**
   - Pass `currentProject.domain` and `currentProject.domainMetadata` to measurement factory

### Data Flow

```
User Input (Files Panel)
  ↓
_CreateProjectBottomSheet collects domain + metadata
  ↓
projectsNotifierProvider.notifier.createProject(...)
  ↓
project_service.createProject(...) → Creates Project with domain fields
  ↓
Project saved to Hive
  ↓
[Later] User records measurement
  ↓
home_screen reads currentProject.domain + currentProject.domainMetadata
  ↓
PneumaGeRecordFactory.createLiveMeasurement(...) populates DomainSpecifics
  ↓
PneumaGeRecord saved to Hive with domain metadata
  ↓
Export includes domain metadata in siteContext.domainSpecifics
```

## Testing

### Manual Test Procedure

1. **Create Agriculture Project**
   ```
   - Launch app
   - Open Files panel
   - Click "Create New Project"
   - Name: "Farm Test"
   - Prefix: "FT"
   - Domain: "Agriculture"
   - Crop Type: "Corn" (required)
   - Growth Stage: "Vegetative"
   - Click "CREATE"
   - Verify project appears in list
   ```

2. **Record Measurement**
   ```
   - With "Farm Test" project active
   - Connect to BLE device
   - Start recording
   - Stop recording
   - Verify measurement saved
   ```

3. **Verify Domain Metadata**
   ```
   - Export project as JSON
   - Open exported JSON file
   - Navigate to siteContext.activeDomain → should be "AGRICULTURE"
   - Navigate to siteContext.domainSpecifics.agriculture
   - Verify cropType: "Corn", growthStage: "Vegetative"
   ```

4. **Test Other Domains**
   - Repeat for Arctic, Maritime, and Volcanology domains
   - Verify numeric fields accept numbers only
   - Verify required field validation works

### Expected Outcomes

✅ Domain dropdown appears in project creation dialog  
✅ Conditional fields appear based on selected domain  
✅ Required field validation prevents project creation  
✅ Numeric field validation rejects non-numeric input  
✅ Project saves with domain and domainMetadata  
✅ Measurements inherit domain information from project  
✅ Exported data includes domain metadata in correct structure  

## Future Enhancements

- [ ] Allow editing domain metadata after project creation
- [ ] Add domain-specific visualizations in analysis panels
- [ ] Support custom domain types with user-defined fields
- [ ] Pre-populate domain fields from previous projects
- [ ] Validate domain field values against controlled vocabularies
- [ ] Add domain metadata to measurement details panel

## Compliance

This implementation follows:
- PneumaGe Master Schema v1.9.0 specification
- Hive type safety with explicit field indices
- Flutter Material Design guidelines for form UI
- Riverpod best practices for state management

## Notes

- Domain is set at project creation and cannot be changed later (future enhancement)
- All domain metadata is optional except fields marked `required: true`
- Numeric fields are stored as `double` in domainMetadata
- Text fields are stored as `String` in domainMetadata
- Empty domain fields are not included in domainMetadata map
- Default domain is 'NONE' with empty domainMetadata
