# On-device model

Put the distilled model here to let the app classify rocks with no internet
connection:

- `geolab_student.tflite`
- `manifest.json`

Both come from `Model_trainig/distillation/export_student.py --tflite` in the
Geolab-Rock-classification repo. Without them the app keeps using the server.
