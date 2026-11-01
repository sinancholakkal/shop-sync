import 'package:flutter_bloc/flutter_bloc.dart';

class NavBarState {
  final int selectedIndex;
  final bool isCompact;

  const NavBarState({
    this.selectedIndex = 0,
    this.isCompact = false,
  });

  NavBarState copyWith({
    int? selectedIndex,
    bool? isCompact,
  }) {
    return NavBarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isCompact: isCompact ?? this.isCompact,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavBarState &&
          runtimeType == other.runtimeType &&
          selectedIndex == other.selectedIndex &&
          isCompact == other.isCompact;

  @override
  int get hashCode => selectedIndex.hashCode ^ isCompact.hashCode;
}

class NavBarCubit extends Cubit<NavBarState> {
  NavBarCubit() : super(const NavBarState());

  void selectTab(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void setCompact(bool compact) {
    if (state.isCompact != compact) {
      emit(state.copyWith(isCompact: compact));
    }
  }

  void expand() => setCompact(false);
  void collapse() => setCompact(true);
}
