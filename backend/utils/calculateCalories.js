function parseHeightToCm(height) {
  if (!height) return 170;
  const lower = height.toString().toLowerCase().trim();
 
  if (lower.includes("cm")) {
    const cm = parseFloat(lower);
    return isNaN(cm) ? 170 : cm;
  }

  if (lower.includes("feet")) {
    const numeric = parseFloat(lower);
    const feet = Math.floor(numeric);
    const fraction = numeric - feet;
    const inches = fraction > 0.12 ? Math.round(fraction * 100) : Math.round(fraction * 12);
    return (feet * 12 + inches) * 2.54;
  }

  return 170;
}

function calculateCalories(height, currentWeight, targetWeight, activityLevel) {
  try {
    const hCm = parseHeightToCm(height);
    const cWeight = parseFloat(currentWeight);
    const tWeight = parseFloat(targetWeight);

    if (!cWeight || !hCm) return 2000;

    // BMR (male, age 25)
    let bmr = 10 * cWeight + 6.25 * hCm - 5 * 25 + 5;

    const activityMultipliers = {
      "not very active": 1.2,
      "somewhat active": 1.375,
      "active": 1.55,
      "very active": 1.725,
    };

    const multiplier =
      activityMultipliers[activityLevel.toLowerCase()] || 1.55;

    let maintenanceCalories = bmr * multiplier;

    const diff = cWeight - tWeight;
    if (diff > 0) maintenanceCalories -= 200;
    else if (diff < 0) maintenanceCalories += 200;
    
    console.log("ℹ️ Calculated calories:", maintenanceCalories);
    return Math.round(maintenanceCalories);
  } catch (err) {
    console.error("⚠️ Calorie calculation failed:", err.message);
    return 2000;
  }
}

module.exports = { calculateCalories };