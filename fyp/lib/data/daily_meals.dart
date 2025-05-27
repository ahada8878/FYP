class Meal {
  final String id;
  final String name;
  final String imageUrl;
  final String time;
  final int calories;
  final String type;
  final String cookingTime;
  final Map<String, String> macronutrients;
  final List<String> ingredients;
  final List<String> cookingSteps;
  final Map<String, bool> dietaryRestrictions;

  Meal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.time,
    required this.calories,
    required this.type,
    required this.cookingTime,
    required this.macronutrients,
    required this.ingredients,
    required this.cookingSteps,
    Map<String, bool>? dietaryRestrictions,
  }) : dietaryRestrictions = dietaryRestrictions ?? {
          'diabetesFriendly': false,
          'hypertensionFriendly': false,
        };

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      time: json['time'] ?? '',
      calories: json['calories'] ?? 0,
      type: json['type'] ?? '',
      cookingTime: json['cookingTime'] ?? '',
      macronutrients: Map<String, String>.from(json['macronutrients'] ?? {}),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      cookingSteps: List<String>.from(json['cookingSteps'] ?? []),
      dietaryRestrictions: Map<String, bool>.from(
          json['dietaryRestrictions'] ?? 
          {
            'diabetesFriendly': false,
            'hypertensionFriendly': false,
          }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'imageUrl': imageUrl,
      'time': time,
      'calories': calories,
      'type': type,
      'cookingTime': cookingTime,
      'macronutrients': macronutrients,
      'ingredients': ingredients,
      'cookingSteps': cookingSteps,
      'dietaryRestrictions': dietaryRestrictions,
    };
  }
}





// class Meal {
//   final String id;
//   final String name;
//   final String imageUrl;
//   final String time;
//   final int calories;
//   final String type;
//   final String cookingTime;
//   final Map<String, String> macronutrients;
//   final List<String> ingredients;
//   final List<String> cookingSteps;

//   Meal({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.time,
//     required this.calories,
//     required this.type,
//     required this.cookingTime,
//     required this.macronutrients,
//     required this.ingredients,
//     required this.cookingSteps,
//   });
// }

List<Meal> getDayMeals(int day) {
  final dayNumber = day % 7;
  switch (dayNumber) {
    case 1:
      return [
        Meal(
          id: '11',
          type: 'Breakfast',
          name: 'Avocado Toast with Egg',
          imageUrl: 'assets/images/avocado-toast-eggs.jpg',
          time: '8:00 AM',
          calories: 350,
          cookingTime: '15 mins',
          macronutrients: {
            'carbs': '35g',
            'protein': '15g',
            'fats': '18g',
            'fiber': '7g'
          },
          ingredients: [
            'Whole grain bread - 2 slices',
            'Avocado - 1 medium',
            'Egg - 1 large',
            'Lemon juice - 1 tbsp',
            'Chili flakes - 1/4 tsp'
          ],
          cookingSteps: [
            'Toast bread to desired crispness',
            'Mash avocado with lemon juice, salt, and pepper',
            'Spread avocado mixture on toast',
            'Fry or poach egg and place on top',
            'Sprinkle with chili flakes'
          ]),
        Meal(
          id: '12',
          type: 'Lunch',
          name: 'Grilled Chicken Salad',
          imageUrl: 'assets/images/Grilled-chicken-salad.jpg',
          time: '1:00 PM',
          calories: 420,
          cookingTime: '25 mins',
          macronutrients: {
            'carbs': '12g',
            'protein': '35g',
            'fats': '22g',
            'fiber': '8g'
          },
          ingredients: [
            'Chicken breast',
            'Mixed greens',
            'Cherry tomatoes',
            'Cucumber',
            'Olive oil'
          ],
          cookingSteps: [
            'Grill chicken',
            'Chop vegetables',
            'Make dressing',
            'Combine all'
          ]),
        Meal(
          id: '13',
          type: 'Dinner',
          name: 'Salmon with Vegetables',
          imageUrl: 'assets/images/Salmon-with-Vegetables.jpg',
          time: '7:30 PM',
          calories: 500,
          cookingTime: '30 mins',
          macronutrients: {
            'carbs': '25g',
            'protein': '40g',
            'fats': '28g',
            'fiber': '6g'
          },
          ingredients: [
            'Salmon fillet',
            'Asparagus',
            'Sweet potato',
            'Lemon',
            'Garlic'
          ],
          cookingSteps: [
            'Roast vegetables',
            'Season salmon',
            'Pan-sear fish',
            'Plate together'
          ]),
      ];

    case 2:
      return [
        Meal(
          id: '21',
          type: 'Breakfast',
          name: 'Greek Yogurt Parfait',
          imageUrl: 'assets/images/Greek-Yogurt-Parfait.jpg',
          time: '7:45 AM',
          calories: 320,
          cookingTime: '5 mins',
          macronutrients: {
            'carbs': '28g',
            'protein': '20g',
            'fats': '10g',
            'fiber': '5g'
          },
          ingredients: [
            'Greek yogurt',
            'Granola',
            'Mixed berries',
            'Honey'
          ],
          cookingSteps: [
            'Layer ingredients',
            'Add toppings',
            'Drizzle honey'
          ]),
        Meal(
          id: '22',
          type: 'Lunch',
          name: 'Quinoa Salad',
          imageUrl: 'assets/images/quinoa-salad.jpg',
          time: '12:30 PM',
          calories: 450,
          cookingTime: '20 mins',
          macronutrients: {
            'carbs': '40g',
            'protein': '18g',
            'fats': '22g',
            'fiber': '9g'
          },
          ingredients: [
            'Quinoa',
            'Chickpeas',
            'Feta',
            'Olives',
            'Lemon'
          ],
          cookingSteps: [
            'Cook quinoa',
            'Mix ingredients',
            'Add dressing'
          ]),
        Meal(
          id: '23',
          type: 'Dinner',
          name: 'Vegetable Curry',
          imageUrl: 'assets/images/vegetable-curry.jpg',
          time: '7:45 PM',
          calories: 410,
          cookingTime: '35 mins',
          macronutrients: {
            'carbs': '30g',
            'protein': '12g',
            'fats': '15g',
            'fiber': '11g'
          },
          ingredients: [
            'Mixed vegetables',
            'Coconut milk',
            'Curry paste',
            'Rice'
          ],
          cookingSteps: [
            'Sauté vegetables',
            'Add curry paste',
            'Simmer with coconut milk',
            'Serve with rice'
          ]),
      ];

    case 3:
      return [
        Meal(
          id: '31',
          type: 'Breakfast',
          name: 'Smoothie Bowl',
          imageUrl: 'assets/images/smoothie-bowl.jpg',
          time: '7:30 AM',
          calories: 280,
          cookingTime: '10 mins',
          macronutrients: {
            'carbs': '38g',
            'protein': '8g',
            'fats': '10g',
            'fiber': '7g'
          },
          ingredients: [
            'Frozen berries',
            'Banana',
            'Almond milk',
            'Granola',
            'Chia seeds'
          ],
          cookingSteps: [
            'Blend fruits',
            'Pour into bowl',
            'Add toppings'
          ]),
        Meal(
          id: '32',
          type: 'Lunch',
          name: 'Caprese Sandwich',
          imageUrl: 'assets/images/caprese-sandwich.jpg',
          time: '12:45 PM',
          calories: 380,
          cookingTime: '15 mins',
          macronutrients: {
            'carbs': '32g',
            'protein': '18g',
            'fats': '20g',
            'fiber': '5g'
          },
          ingredients: [
            'Ciabatta bread',
            'Fresh mozzarella',
            'Tomato',
            'Basil',
            'Balsamic glaze'
          ],
          cookingSteps: [
            'Slice ingredients',
            'Assemble sandwich',
            'Drizzle glaze'
          ]),
        Meal(
          id: '33',
          type: 'Dinner',
          name: 'Lentil Curry',
          imageUrl: 'assets/images/lentil-curry.jpg',
          time: '7:15 PM',
          calories: 420,
          cookingTime: '40 mins',
          macronutrients: {
            'carbs': '45g',
            'protein': '22g',
            'fats': '12g',
            'fiber': '15g'
          },
          ingredients: [
            'Red lentils',
            'Coconut milk',
            'Spinach',
            'Tomatoes',
            'Spices'
          ],
          cookingSteps: [
            'Cook lentils',
            'Sauté spices',
            'Combine ingredients',
            'Simmer'
          ]),
      ];

    case 4:
      return [
        Meal(
          id: '41',
          type: 'Breakfast',
          name: 'Smoked Salmon Bagel',
          imageUrl: 'assets/images/smoked-salmon-bagel.jpg',
          time: '8:15 AM',
          calories: 380,
          cookingTime: '10 mins',
          macronutrients: {
            'carbs': '32g',
            'protein': '25g',
            'fats': '18g',
            'fiber': '4g'
          },
          ingredients: [
            'Whole grain bagel',
            'Smoked salmon',
            'Cream cheese',
            'Capers',
            'Red onion'
          ],
          cookingSteps: [
            'Toast bagel',
            'Spread cream cheese',
            'Layer salmon',
            'Add toppings'
          ]),
        Meal(
          id: '42',
          type: 'Lunch',
          name: 'Shrimp Pasta',
          imageUrl: 'assets/images/shrimp-pasta.jpg',
          time: '1:15 PM',
          calories: 480,
          cookingTime: '25 mins',
          macronutrients: {
            'carbs': '45g',
            'protein': '35g',
            'fats': '18g',
            'fiber': '6g'
          },
          ingredients: [
            'Spaghetti',
            'Shrimp',
            'Garlic',
            'Olive oil',
            'Parmesan'
          ],
          cookingSteps: [
            'Cook pasta',
            'Sauté shrimp',
            'Combine ingredients',
            'Garnish'
          ]),
        Meal(
          id: '43',
          type: 'Dinner',
          name: 'Stuffed Bell Peppers',
          imageUrl: 'assets/images/stuffed-bell-peppers.jpg',
          time: '7:45 PM',
          calories: 360,
          cookingTime: '45 mins',
          macronutrients: {
            'carbs': '28g',
            'protein': '20g',
            'fats': '15g',
            'fiber': '8g'
          },
          ingredients: [
            'Bell peppers',
            'Ground turkey',
            'Quinoa',
            'Tomato sauce',
            'Cheese'
          ],
          cookingSteps: [
            'Prep peppers',
            'Cook filling',
            'Stuff peppers',
            'Bake'
          ]),
      ];

    case 5:
      return [
        Meal(
          id: '51',
          type: 'Breakfast',
          name: 'Protein Pancakes',
          imageUrl: 'assets/images/protein-pancakes.jpg',
          time: '7:45 AM',
          calories: 320,
          cookingTime: '20 mins',
          macronutrients: {
            'carbs': '25g',
            'protein': '30g',
            'fats': '8g',
            'fiber': '5g'
          },
          ingredients: [
            'Protein powder',
            'Oats',
            'Egg whites',
            'Banana',
            'Maple syrup'
          ],
          cookingSteps: [
            'Mix batter',
            'Cook pancakes',
            'Add toppings'
          ]),
        Meal(
          id: '52',
          type: 'Lunch',
          name: 'Chicken Burger',
          imageUrl: 'assets/images/chicken-burger.jpg',
          time: '12:30 PM',
          calories: 520,
          cookingTime: '25 mins',
          macronutrients: {
            'carbs': '35g',
            'protein': '40g',
            'fats': '25g',
            'fiber': '6g'
          },
          ingredients: [
            'Chicken patty',
            'Whole wheat bun',
            'Lettuce',
            'Tomato',
            'Guacamole'
          ],
          cookingSteps: [
            'Grill patty',
            'Toast bun',
            'Assemble burger'
          ]),
        Meal(
          id: '53',
          type: 'Dinner',
          name: 'Beef Meatloaf',
          imageUrl: 'assets/images/beef-meatloaf.jpg',
          time: '7:30 PM',
          calories: 580,
          cookingTime: '60 mins',
          macronutrients: {
            'carbs': '20g',
            'protein': '45g',
            'fats': '35g',
            'fiber': '4g'
          },
          ingredients: [
            'Ground beef',
            'Breadcrumbs',
            'Egg',
            'Ketchup',
            'Vegetables'
          ],
          cookingSteps: [
            'Mix ingredients',
            'Shape loaf',
            'Bake',
            'Glaze'
          ]),
      ];

    case 6:
      return [
        Meal(
          id: '61',
          type: 'Breakfast',
          name: 'Breakfast Burrito',
          imageUrl: 'assets/images/Breakfast-Burrito.jpg',
          time: '8:00 AM',
          calories: 380,
          cookingTime: '15 mins',
          macronutrients: {
            'carbs': '30g',
            'protein': '20g',
            'fats': '18g',
            'fiber': '6g'
          },
          ingredients: [
            'Tortilla',
            'Scrambled eggs',
            'Black beans',
            'Salsa',
            'Avocado'
          ],
          cookingSteps: [
            'Scramble eggs',
            'Warm tortilla',
            'Assemble fillings',
            'Roll burrito'
          ]),
        Meal(
          id: '62',
          type: 'Lunch',
          name: 'Caesar Wrap',
          imageUrl: 'assets/images/Caesar-Wrap.jpg',
          time: '12:45 PM',
          calories: 420,
          cookingTime: '10 mins',
          macronutrients: {
            'carbs': '28g',
            'protein': '25g',
            'fats': '22g',
            'fiber': '5g'
          },
          ingredients: [
            'Grilled chicken',
            'Romaine lettuce',
            'Parmesan',
            'Wrap',
            'Caesar dressing'
          ],
          cookingSteps: [
            'Chop ingredients',
            'Assemble wrap',
            'Add dressing'
          ]),
        Meal(
          id: '63',
          type: 'Dinner',
          name: 'Vegetable Stir-Fry',
          imageUrl: 'assets/images/Vegetable-Stir-Fry.jpg',
          time: '7:15 PM',
          calories: 360,
          cookingTime: '20 mins',
          macronutrients: {
            'carbs': '25g',
            'protein': '18g',
            'fats': '12g',
            'fiber': '8g'
          },
          ingredients: [
            'Mixed vegetables',
            'Tofu',
            'Soy sauce',
            'Sesame oil',
            'Ginger'
          ],
          cookingSteps: [
            'Press tofu',
            'Stir-fry vegetables',
            'Add sauce',
            'Combine'
          ]),
      ];

    case 0: // Day 7
      return [
        Meal(
          id: '71',
          type: 'Breakfast',
          name: 'Eggs Benedict',
          imageUrl: 'assets/images/Eggs-Benedict.jpg',
          time: '8:30 AM',
          calories: 450,
          cookingTime: '25 mins',
          macronutrients: {
            'carbs': '22g',
            'protein': '25g',
            'fats': '28g',
            'fiber': '3g'
          },
          ingredients: [
            'English muffin',
            'Poached egg',
            'Canadian bacon',
            'Hollandaise'
          ],
          cookingSteps: [
            'Poach eggs',
            'Toast muffin',
            'Assemble',
            'Add sauce'
          ]),
        Meal(
          id: '72',
          type: 'Lunch',
          name: 'Steak Salad',
          imageUrl: 'assets/images/Steak-Salad.jpg',
          time: '1:00 PM',
          calories: 520,
          cookingTime: '30 mins',
          macronutrients: {
            'carbs': '15g',
            'protein': '45g',
            'fats': '35g',
            'fiber': '6g'
          },
          ingredients: [
            'Sirloin steak',
            'Arugula',
            'Cherry tomatoes',
            'Parmesan',
            'Balsamic'
          ],
          cookingSteps: [
            'Grill steak',
            'Slice',
            'Assemble salad',
            'Dress'
          ]),
        Meal(
          id: '73',
          type: 'Dinner',
          name: 'Lamb Chops',
          imageUrl: 'assets/images/Lamb-Chops.jpg',
          time: '7:45 PM',
          calories: 620,
          cookingTime: '35 mins',
          macronutrients: {
            'carbs': '18g',
            'protein': '50g',
            'fats': '40g',
            'fiber': '4g'
          },
          ingredients: [
            'Lamb chops',
            'Rosemary',
            'Garlic',
            'Mint sauce',
            'Roasted potatoes'
          ],
          cookingSteps: [
            'Season lamb',
            'Pan-sear',
            'Roast',
            'Serve with sides'
          ]),
      ];

    default:
      return [];
  }
}