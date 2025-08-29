#!/bin/bash

# Build script for generating JSON serialization files
echo "🔄 Generating JSON serialization files..."

# Run build runner to generate .g.dart files
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "✅ JSON serialization files generated successfully!"
echo "📁 Generated files:"
echo "  - lib/models/user_model.g.dart"
echo "  - lib/models/prediction_model.g.dart"
echo "  - lib/models/feedback_model.g.dart"
echo "  - lib/models/subscription_model.g.dart" 