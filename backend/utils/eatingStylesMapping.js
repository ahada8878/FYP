// utils/eatingStylesMapping.js

function mapEatingStylesToDiet(eatingStyles) {
  if (!eatingStyles) return null;

  // If it's a Mongoose Map, convert to plain object
  if (typeof eatingStyles.toObject === "function") {
    eatingStyles = eatingStyles.toObject();
  }

  // If it's still a Map, convert it
  if (eatingStyles instanceof Map) {
    eatingStyles = Object.fromEntries(eatingStyles);
  }

  console.log("🟡 Normalized eatingStyles:", eatingStyles);

  // Define mapping
  const mapping = {
    Vegan: "vegan",
    Vegetarian: "vegetarian",
    "Keto": "ketogenic",
    "Paleo": "paleo",
    "I eat everything": null, // default diet
  };

  // Find the first "true" eating style
  for (const [style, selected] of Object.entries(eatingStyles)) {
    if (selected === true && mapping[style]) {
      return mapping[style];
    }
  }

  return null; // fallback if nothing matched
}

module.exports = { mapEatingStylesToDiet };
