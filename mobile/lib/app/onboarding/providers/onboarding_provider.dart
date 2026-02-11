import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/onboarding_data.dart';

/// Total number of pages in the onboarding flow.
const int onboardingPageCount = 11;

/// State for the onboarding flow.
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.data = const OnboardingData(),
    this.isLoading = false,
  });

  final int currentPage;
  final OnboardingData data;
  final bool isLoading;

  OnboardingState copyWith({
    int? currentPage,
    OnboardingData? data,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Whether the user has provided enough input to proceed from the current page.
  bool get canProceed {
    switch (currentPage) {
      case 0: // Welcome
        return true;
      case 1: // Goals
        return data.goals.isNotEmpty;
      case 2: // Pain point
        return true;
      case 3: // Recipe sources
        return data.recipeSources.isNotEmpty;
      case 4: // Import demo
        return true;
      case 5: // Organization
        return data.organizationMethod != null;
      case 6: // Cookbook feature
        return true;
      case 7: // Pantry setup
        return true; // can skip
      case 8: // Grocery feature
        return true;
      case 9: // Share feature
        return true;
      case 10: // Better cook
        return true;
      default:
        return true;
    }
  }

  double get progress => (currentPage + 1) / onboardingPageCount;
}

/// Notifier managing the onboarding flow state.
class OnboardingNotifier extends Notifier<OnboardingState> {
  final PageController pageController = PageController();

  @override
  OnboardingState build() {
    ref.onDispose(() {
      pageController.dispose();
    });
    return const OnboardingState();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> nextPage() async {
    if (state.currentPage < onboardingPageCount - 1) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> previousPage() async {
    if (state.currentPage > 0) {
      await pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Goal selection ---

  void toggleGoal(String goal) {
    final goals = List<String>.from(state.data.goals);
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else {
      goals.add(goal);
    }
    state = state.copyWith(data: state.data.copyWith(goals: goals));
  }

  // --- Recipe source selection ---

  void toggleRecipeSource(String source) {
    final sources = List<String>.from(state.data.recipeSources);
    if (sources.contains(source)) {
      sources.remove(source);
    } else {
      sources.add(source);
    }
    state = state.copyWith(data: state.data.copyWith(recipeSources: sources));
  }

  // --- Organization method ---

  void setOrganizationMethod(String method) {
    state = state.copyWith(
      data: state.data.copyWith(organizationMethod: method),
    );
  }

  // --- Pantry items ---

  void togglePantryItem(String item) {
    final items = List<String>.from(state.data.pantryItems);
    if (items.contains(item)) {
      items.remove(item);
    } else {
      items.add(item);
    }
    state = state.copyWith(data: state.data.copyWith(pantryItems: items));
  }

  // --- Pro subscription ---

  void setProSubscription(bool subscribed) {
    state = state.copyWith(
      data: state.data.copyWith(subscribedToPro: subscribed),
    );
  }

  // --- Loading ---

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
