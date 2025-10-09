// utils/extractRecipeDetails.js

function extractRecipeDetails(recipe) {
  // Extract ingredients
  const ingredients =
    recipe.extendedIngredients?.map((ing) => ({
      id: ing.id,
      name: ing.name,
      amount: ing.amount,
      unit: ing.unit,
    })) || [];

  // Extract instructions (flattened steps text)
  const instructions =
    recipe.analyzedInstructions?.[0]?.steps
      ?.map((step) => step.step)
      .join(" ") || recipe.instructions || "";

  // Extract nutrition info
  const nutrients = {};
  if (recipe.nutrition?.nutrients) {
    const findNutrient = (name) =>
      recipe.nutrition.nutrients.find((n) => n.name.toLowerCase() === name.toLowerCase())?.amount || null;

    nutrients.calories = findNutrient("Calories");
    nutrients.carbs = findNutrient("Carbohydrates");
    nutrients.protein = findNutrient("Protein");
    nutrients.fat = findNutrient("Fat");
    nutrients.fiber = findNutrient("Fiber");
  }

  return {
    id: recipe.id,
    title: recipe.title,
    image: recipe.image,
    readyInMinutes: recipe.readyInMinutes,
    servings: recipe.servings,
    sourceUrl: recipe.sourceUrl,
    ingredients,
    instructions,
    nutrients,
  };
}

module.exports = { extractRecipeDetails };
