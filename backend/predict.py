import tensorflow as tf
import numpy as np
import sys
import json
from PIL import Image
import os
import warnings

# Disable all warnings and TensorFlow progress output
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3' 
tf.get_logger().setLevel('ERROR')
warnings.filterwarnings('ignore')

def load_model():
    model = tf.keras.models.load_model('mobilenetv2_food101.h5')
    # Disable progress bar
    model.compile(optimizer='adam', 
                loss='sparse_categorical_crossentropy',
                metrics=['accuracy'],
                run_eagerly=True)  # Disables progress bar
    return model

model = load_model()

def predict(image_path):
    try:
        # Disable TensorFlow's output
        tf.keras.utils.disable_interactive_logging()
        
        img = Image.open(image_path).resize((224, 224))
        img_array = np.array(img) / 127.5 - 1.0
        img_array = np.expand_dims(img_array, axis=0)
        
        # Silent prediction
        with tf.device('/CPU:0'):  # Ensures no GPU progress messages
            pred = model.predict(img_array, verbose=0)
        
        return json.dumps({
            'success': True,
            'class_index': int(np.argmax(pred)),
            'confidence': float(np.max(pred)),
            'predictions': pred[0].tolist()
        })
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })

if __name__ == '__main__':
    try:
        image_path = sys.argv[1]
        print(predict(image_path))  # Single clean JSON output
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': f"System error: {str(e)}"
        }))