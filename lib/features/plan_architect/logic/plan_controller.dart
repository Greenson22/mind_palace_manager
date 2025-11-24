// lib/features/plan_architect/logic/plan_controller.dart
import 'mixins/plan_variables.dart';
import 'mixins/plan_state_mixin.dart';
import 'mixins/plan_view_mixin.dart';
import 'mixins/plan_tool_mixin.dart'; // Critical
import 'mixins/plan_image_mixin.dart';
import 'mixins/plan_input_mixin.dart';
import 'mixins/plan_selection_core_mixin.dart';
import 'mixins/plan_transform_mixin.dart';
import 'mixins/plan_group_mixin.dart';
import 'mixins/plan_edit_mixin.dart';
import 'plan_enums.dart';

export 'plan_enums.dart';

class PlanController extends PlanVariables
    with
        PlanStateMixin,
        PlanViewMixin,
        PlanToolMixin,
        PlanImageMixin,
        PlanSelectionCoreMixin,
        PlanTransformMixin,
        PlanGroupMixin,
        PlanEditMixin,
        PlanInputMixin {
  PlanController() {
    activeTool = PlanTool.select;
    initFloors();
  }
}
