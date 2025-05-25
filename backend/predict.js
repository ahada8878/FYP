const { spawn } = require('child_process');
const path = require('path');

const foodLabels = [
    "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare", "beet_salad", 
    "beignets", "bibimbap", "bread_pudding", "breakfast_burrito", "bruschetta", "caesar_salad", 
    "cannoli", "caprese_salad", "carrot_cake", "ceviche", "cheese_plate", "cheesecake", 
    "chicken_curry", "chicken_quesadilla", "chicken_wings", "chocolate_cake", "chocolate_mousse", 
    "churros", "clam_chowder", "club_sandwich", "crab_cakes", "creme_brulee", "croque_madame", 
    "cup_cakes", "deviled_eggs", "donuts", "dumplings", "edamame", "eggs_benedict", "escargots", 
    "falafel", "filet_mignon", "fish_and_chips", "foie_gras", "french_fries", "french_onion_soup", 
    "french_toast", "fried_calamari", "fried_rice", "frozen_yogurt", "garlic_bread", "gnocchi", 
    "greek_salad", "grilled_cheese_sandwich", "grilled_salmon", "guacamole", "gyoza", "hamburger", 
    "hot_and_sour_soup", "hot_dog", "huevos_rancheros", "hummus", "ice_cream", "lasagna", "lobster_bisque", 
    "lobster_roll_sandwich", "macaroni_and_cheese", "macarons", "miso_soup", "mussels", "nachos", "omelette", 
    "onion_rings", "oysters", "pad_thai", "paella", "pancakes", "panna_cotta", "peking_duck", "pho", "pizza", 
    "pork_chop", "poutine", "prime_rib", "pulled_pork_sandwich", "ramen", "ravioli", "red_velvet_cake", 
    "risotto", "samosa", "sashimi", "scallops", "seaweed_salad", "shrimp_and_grits", "spaghetti_bolognese", 
    "spaghetti_carbonara", "spring_rolls", "steak", "strawberry_shortcake", "sushi", "tacos", "takoyaki", 
    "tiramisu", "tuna_tartare", "waffles"
];

async function predictViaPython(imagePath) {
    return new Promise((resolve, reject) => {
        const python = spawn('python', [
            path.resolve(__dirname, 'predict.py'), 
            path.resolve(imagePath)
        ]);

        let stdoutData = '';
        let stderrData = '';

        python.stdout.on('data', (data) => {
            stdoutData += data.toString();
        });

        python.stderr.on('data', (data) => {
            stderrData += data.toString();
        });

        python.on('close', (code) => {
            if (code !== 0) {
                return reject(new Error(`Python process exited with code ${code}: ${stderrData}`));
            }

            try {
                // Find the JSON part in stdout (handles any remaining TensorFlow output)
                const jsonStart = stdoutData.indexOf('{');
                const jsonEnd = stdoutData.lastIndexOf('}') + 1;
                const jsonString = stdoutData.slice(jsonStart, jsonEnd);
                
                const result = JSON.parse(jsonString);
                
                if (result.success) {
                    result.label = foodLabels[result.class_index];
                    resolve(result);
                } else {
                    reject(new Error(`Python prediction failed: ${result.error || 'Unknown error'}`));
                }
            } catch (e) {
                reject(new Error(`Failed to parse Python output: ${e.message}\nFull output: ${stdoutData}`));
            }
        });
    });
}

// Usage with proper error handling
(async () => {
    try {
        const imagePath = path.resolve(__dirname, 'image.jpg');
        console.log(`Processing image: ${imagePath}`);
        
        const result = await predictViaPython(imagePath);
        
        console.log('\nPrediction Results:');
        console.log('------------------');
        console.log(`🍽️  Food: ${result.label}`);
        console.log(`🔢 Class Index: ${result.class_index}`);
        console.log(`📊 Confidence: ${(result.confidence * 100).toFixed(2)}%`);
    } catch (error) {
        console.error('❌ Prediction failed:', error.message);
        process.exit(1);
    }
})();
