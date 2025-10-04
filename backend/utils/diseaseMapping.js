// utils/diseaseMapping.js

// Map diseases to ingredients that should be excluded
const diseaseToExclude = {
  Hypertension: ["salt", "pickles", "processed meat", "canned soup"],
  "High Cholesterol": ["butter", "fried food", "red meat", "cheese"],
  Obesity: ["soda", "fast food", "fried food", "sweets"],
  Diabetes: ["sugar", "honey", "white bread", "white rice", "soda"],
  "Heart Disease": ["processed meat", "trans fats", "butter", "cheese"],
  Arthritis: ["red meat", "fried food", "processed sugar"],
  Asthma: ["sulfites", "wine", "beer", "shrimp"],
};

function getExcludedIngredientsFromHealthConcerns(healthConcerns = {}) {
  let exclude = [];

  // healthConcerns is a Map in Mongo, but will come as object in req.body
  const entries = Object.entries(healthConcerns);

  entries.forEach(([disease, active]) => {
    if (active && diseaseToExclude[disease]) {
      exclude = exclude.concat(diseaseToExclude[disease]);
    }
  });

  // Remove duplicates
  exclude = [...new Set(exclude)];
  return exclude.join(",");
}

module.exports = { getExcludedIngredientsFromHealthConcerns };
