// Copyright 2026 PneumaGe Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

enum LeftPanel {
  files,
  stats,
  info,
  settings,
  export,
}

enum RightPanel {
  timeSeries,
  histogram,
}

class PanelConfig {
  // Fixed fraction of total center width each panel consumes.
  static double leftFraction(LeftPanel panel) {
    switch (panel) {
      case LeftPanel.info:
        return 0.25;
      case LeftPanel.stats:
        return 0.25;
      case LeftPanel.files:
        return 0.50;
      case LeftPanel.export:
        return 0.40;
      case LeftPanel.settings:
        return 1.0; // full — handled separately
    }
  }

  static double rightFraction(RightPanel panel) {
    switch (panel) {
      case RightPanel.timeSeries:
        return 0.50;
      case RightPanel.histogram:
        return 0.50;
    }
  }
}
