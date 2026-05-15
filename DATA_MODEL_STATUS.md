# PneumaGe Master Schema v1.9.0 - Implementation Status

**Last Updated:** May 15, 2026

## ✅ Phase 1: Core Data Model (COMPLETE)

### Completed Tasks
- [x] Implemented all 12 new classes with Hive adapters
  - PneumaGeRecord, Provenance, SensorPayload, SiteContext, Coordinates
  - EnvironmentalData, DomainSpecifics, MeasurementCycle, SystemVitals
  - FluxChannel, CalibrationData, ChannelData, CalculatedFlux
- [x] Added `fluxError` field to CalculatedFlux
- [x] Fixed Hive typeId conflicts (assigned typeIds 22-33)
- [x] Created backward compatibility layer
  - Sample class, MeasurementStats class
  - PneumaGeRecordHelpers extension methods
  - PneumaGeRecordFactory for creating/updating records
- [x] Updated all services (project, sync, export)
- [x] Updated all providers (project, measurement selection)
- [x] Updated all UI components with minimal changes
- [x] Fixed channel name case sensitivity (CO2, CH4, Temperature, Pressure)
- [x] Fixed raw vs filtered data storage
- [x] Fixed Temperature/Pressure channel display
- [x] Implemented dynamic filter toggle based on settings
- [x] Fixed boundary capture to use rawData

### Architecture
- **Hierarchical Structure:** Multi-channel architecture with separate raw/filtered data
- **Storage:** Raw data in `rawData`, filtered data in `filteredData` per channel
- **Statistics:** RANSAC results saved to `rawData.calculatedFlux`
- **Filter Control:** Dynamic `useFiltered` flag based on settings panel checkboxes

---

## 🔄 Phase 2: System Vitals Integration (IN PROGRESS)

### Priority: HIGH
System vitals are already captured in the data model but need proper integration.

### Current Status
- [x] SystemVitals class defined with all fields
- [x] Basic default values set during measurement creation
- [ ] **TODO:** Capture real-time system vitals from BLE service
  - Battery voltage (batteryMv)
  - Pump PWM duty cycle (pumpPwmDutyPct)
  - Chamber tilt (pitch/roll from accelerometer)
  - Shock detection flag

### Implementation Tasks
1. **Update home_screen.dart data collection**
   - Read battery voltage from `dataService.batteryLevel` (convert to mV)
   - Get pump PWM from settings/BLE service
   - Add accelerometer data if available
   - Update `SystemVitals` when creating measurement

2. **Add to Settings Panel**
   - Display current system vitals in real-time
   - Battery indicator widget
   - Tilt indicator (pitch/roll display)

3. **Export Integration**
   - Include system vitals in JSON/CSV exports
   - Add metadata fields to export headers

---

## 📋 Phase 3: Domain Specifics (PENDING)

### Priority: MEDIUM
Domain-specific metadata fields for different use cases.

### Current Status
- [x] DomainSpecifics class defined with 4 domain maps
- [ ] **TODO:** Settings panel UI for domain metadata
- [ ] **TODO:** Populate domain fields during measurement

### Implementation Tasks

#### 3.1 Settings Panel Enhancement
Create a new tab or section in Settings for domain-specific configuration:

**Agriculture Domain:**
- Crop type (dropdown)
- Growth stage (dropdown)
- Fertilizer application (boolean + date picker)
- Irrigation status (dropdown)
- Soil type (text)

**Arctic Domain:**
- Permafrost depth (number input)
- Active layer thickness (number input)
- Snow cover depth (number input)
- Thaw status (dropdown)

**Maritime Domain:**
- Water depth (number input)
- Salinity (number input)
- Current speed (number input)
- Wave height (number input)

**Volcanology Domain:**
- Fumarole activity (dropdown)
- Ground temperature (number input)
- Seismic activity level (dropdown)

#### 3.2 Project Configuration
- Add domain selection to project creation
- Store preferred domain in Project model
- Auto-populate domain fields based on project settings

#### 3.3 Measurement Integration
- Update `createLiveMeasurement` to include domain data from settings
- Add UI in home screen to show active domain
- Include domain metadata in exports

---

## 👤 Phase 4: Provenance Enhancement (PENDING)

### Priority: MEDIUM
User profile and operator information for measurement provenance.

### Current Status
- [x] Provenance class with required fields
- [x] Basic defaults during measurement creation
- [ ] **TODO:** User profile management
- [ ] **TODO:** Organization settings
- [ ] **TODO:** Operator ID tracking

### Implementation Tasks

#### 4.1 User Profile Panel
Create new Settings section for user profile:
- **Creator Name** (text input)
- **Organization** (text input)
- **Operator ID** (text input, defaults to email/username)
- **System ID** (display device ID)
- Save to Hive `AppSettings`

#### 4.2 Measurement Integration
- Read profile from AppSettings
- Populate Provenance fields during measurement creation
- Display operator info in measurement details view

#### 4.3 Export Enhancement
- Include provenance metadata in exports
- Add creator/organization to export file headers
- SPDX/DataCite metadata generation for data sharing

---

## 🧪 Phase 5: Testing & Validation (IN PROGRESS)

### Test Coverage

#### Functional Tests
- [x] Live data capture works
- [x] Historical data loads correctly
- [x] Time series visualization displays data
- [x] RANSAC analysis runs on historical data
- [x] Boundary dragging works
- [ ] **TODO:** Statistics persistence verification (debug output added)
- [ ] **TODO:** Filter toggle affects displayed data
- [ ] **TODO:** Export includes correct data (raw vs filtered)

#### Edge Cases
- [ ] Empty measurements (no samples)
- [ ] Single-channel measurements
- [ ] Very long measurements (>1000 samples)
- [ ] Measurements with missing GPS data
- [ ] Corrupt/incomplete measurements

#### Integration Tests
- [ ] Cloud sync with new data model
- [ ] Export/import round-trip
- [ ] Multiple devices with different configurations
- [ ] Settings persistence across app restarts

---

## 📊 Phase 6: Data Validation & QA/QC (FUTURE)

### Priority: LOW (Future Enhancement)
Automated quality assurance and quality control.

### Planned Features
1. **Automatic QA/QC Flags**
   - Detect anomalous readings (spike detection)
   - Flag low R² values
   - Detect chamber seal issues (pressure drops)
   - Battery low warnings

2. **Data Quality Metrics**
   - Signal-to-noise ratio
   - Fit quality indicators
   - Confidence intervals
   - Residual analysis

3. **Manual Review Interface**
   - Flag/unflag measurements
   - Add review notes
   - Mark as "approved" or "rejected"
   - Reason codes for rejection

---

## 🎯 Immediate Next Steps (Priority Order)

1. **Verify Statistics Persistence** 
   - Run app with debug output
   - Record measurement, run RANSAC, check console
   - Reload measurement and verify stats are retained
   - **ETA:** 10 minutes testing

2. **Test Filter Toggle**
   - Enable Alpha-Beta filter in Settings
   - Record measurement
   - Verify filtered data is displayed in time series panel
   - Export and check CSV contains filtered values
   - **ETA:** 15 minutes testing

3. **Capture Real System Vitals**
   - Update home_screen.dart to read battery/pump/tilt
   - Test with real device
   - Verify values in exported JSON
   - **ETA:** 2 hours development + testing

4. **Add Domain Specifics UI**
   - Create domain configuration panel in Settings
   - Add project-level domain selection
   - Populate DomainSpecifics during measurement
   - **ETA:** 4-6 hours development

5. **Create User Profile Panel**
   - Add profile settings UI
   - Save to AppSettings
   - Auto-populate Provenance fields
   - **ETA:** 2-3 hours development

---

## 📝 Notes

### Migration Strategy
- ✅ Old data deleted on first launch (one-time migration)
- ✅ No backward compatibility needed
- Users should export old data before updating if needed

### Known Limitations
- Temperature/Pressure channels capture values but no flux calculation (by design)
- Filtered data storage exists but filters not yet applied during live capture
- Domain specifics captured but no validation rules yet
- SensorPayload array is empty (future: support multiple sensor heads)

### Data Storage Efficiency
- Hive binary format is efficient for local storage
- JSON exports readable but large for long sessions
- Consider compression for cloud sync (future)

### Performance Considerations
- Current implementation handles ~1000 samples smoothly
- RANSAC calculation is fast (<100ms for typical datasets)
- UI responsive during real-time capture
- Export times acceptable for typical projects
