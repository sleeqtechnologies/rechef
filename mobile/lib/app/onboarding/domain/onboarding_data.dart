import 'dart:convert';

class OnboardingData {
  const OnboardingData({
    this.goals = const [],
    this.recipeSources = const [],
    this.organizationMethod,
    this.pantryItems = const [],
    this.subscribedToPro = false,
  });

  final List<String> goals;
  final List<String> recipeSources;
  final String? organizationMethod;
  final List<String> pantryItems;
  final bool subscribedToPro;

  OnboardingData copyWith({
    List<String>? goals,
    List<String>? recipeSources,
    String? organizationMethod,
    List<String>? pantryItems,
    bool? subscribedToPro,
  }) {
    return OnboardingData(
      goals: goals ?? this.goals,
      recipeSources: recipeSources ?? this.recipeSources,
      organizationMethod: organizationMethod ?? this.organizationMethod,
      pantryItems: pantryItems ?? this.pantryItems,
      subscribedToPro: subscribedToPro ?? this.subscribedToPro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'recipeSources': recipeSources,
      'organizationMethod': organizationMethod,
      'pantryItems': pantryItems,
      'subscribedToPro': subscribedToPro,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      goals: List<String>.from(json['goals'] ?? []),
      recipeSources: List<String>.from(json['recipeSources'] ?? []),
      organizationMethod: json['organizationMethod'] as String?,
      pantryItems: List<String>.from(json['pantryItems'] ?? []),
      subscribedToPro: json['subscribedToPro'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory OnboardingData.fromJsonString(String jsonString) {
    return OnboardingData.fromJson(jsonDecode(jsonString));
  }
}

/// Available goals for the onboarding goals page.
class OnboardingGoals {
  OnboardingGoals._();

  static const saveRecipes = 'save_recipes';
  static const cookMore = 'cook_more';
  static const eatHealthier = 'eat_healthier';
  static const mealPlan = 'meal_plan';
  static const reduceFoodWaste = 'reduce_food_waste';
  static const tryNewCuisines = 'try_new_cuisines';
  static const cookFaster = 'cook_faster';

  static const Map<String, String> labels = {
    saveRecipes: 'goals.save_recipes',
    cookMore: 'goals.cook_more',
    eatHealthier: 'goals.eat_healthier',
    mealPlan: 'goals.meal_plan',
    reduceFoodWaste: 'goals.reduce_food_waste',
    tryNewCuisines: 'goals.try_new_cuisines',
    cookFaster: 'goals.cook_faster',
  };
}

/// Available recipe sources for the onboarding sources page.
class RecipeSources {
  RecipeSources._();

  static const tiktok = 'tiktok';
  static const instagram = 'instagram';
  static const youtube = 'youtube';
  static const pinterest = 'pinterest';
  static const foodBlogs = 'food_blogs';
  static const cookbooks = 'cookbooks';
  static const friendsFamily = 'friends_family';
  static const other = 'other';

  static const Map<String, String> labels = {
    tiktok: 'sources.tiktok',
    instagram: 'sources.instagram',
    youtube: 'sources.youtube',
    pinterest: 'sources.pinterest',
    foodBlogs: 'sources.food_blogs',
    cookbooks: 'sources.cookbooks',
    friendsFamily: 'sources.friends_family',
    other: 'sources.other',
  };
}

/// Available organization methods for the onboarding organization page.
class OrganizationMethods {
  OrganizationMethods._();

  static const screenshots = 'screenshots';
  static const bookmarks = 'bookmarks';
  static const notesApp = 'notes_app';
  static const dontOrganize = 'dont_organize';

  static const Map<String, String> labels = {
    screenshots: 'organization.screenshots',
    bookmarks: 'organization.bookmarks',
    notesApp: 'organization.notes_app',
    dontOrganize: 'organization.dont_organize',
  };
}
