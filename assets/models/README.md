# YAMNet TFLite Model Directory

To run real on-device classification without simulation mode:
1. Download `lite-model_yamnet_tflite_1.tflite` from TensorFlow Hub:
   https://tfhub.dev/google/lite-model/yamnet/tflite/1
2. Rename the file to `yamnet.tflite` and place it in this directory (`assets/models/yamnet.tflite`).
3. The model takes 15,600 audio samples (0.975s at 16kHz) and outputs probabilities across 521 AudioSet classes.
