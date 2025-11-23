// lib/features/plan_architect/logic/plan_controller.dart
import 'mixins/plan_variables.dart';
import 'mixins/plan_state_mixin.dart';
import 'mixins/plan_view_mixin.dart';
import 'mixins/plan_tool_mixin.dart';
import 'mixins/plan_image_mixin.dart';
import 'mixins/plan_selection_mixin.dart';
import 'mixins/plan_input_mixin.dart';
import 'plan_enums.dart';

// Export Enum agar file lain bisa pakai
export 'plan_enums.dart';

class PlanController extends PlanVariables
    with
        PlanStateMixin,
        PlanViewMixin,
        PlanToolMixin,
        PlanImageMixin,
        PlanSelectionMixin,
        PlanInputMixin {
  PlanController() {
    // Inisialisasi
    activeTool = PlanTool.select;
    initFloors();
  }
}
