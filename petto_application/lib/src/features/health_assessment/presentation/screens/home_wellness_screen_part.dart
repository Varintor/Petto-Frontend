part of 'home_screen.dart';

extension _HomeWellnessScreenPart on _HomeScreenState {
  Widget _buildWellnessView(BuildContext context) {
    return WellnessTrackingView(petName: _activePet.name);
  }
}
