# GeoLab - Rock Classification & XAI System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)

</div>

**GeoLab** is a comprehensive rock classification application designed for geologists, students, and enthusiasts. It leverages advanced machine learning models to identify rock types (Igneous, Sedimentary, Metamorphic) and provides Explainable AI (XAI) insights to help users understand the classification reasoning.

## 🚀 Key Features

- **📸 Real-time Classification**: Instantly identify rocks using your camera or gallery.
- **🧠 Explainable AI (XAI)**: Understand *why* a rock was classified a certain way with visual heatmaps and confidence scores.
- **🔁 Feedback Loop**: improved model accuracy by allowing users to provide feedback on predictions.
- **🔐 Secure Authentication**: User profiles and data sync powered by Supabase.
- **📜 History & Tracking**: Keep a log of all your classified samples.
- **🌓 Dark & Light Mode**: Seamless theming support for field or lab use.

## 🛠️ Architecture

The project follows a clean **MVC + BLoC** architecture for scalability and maintainability.
For detailed architecture documentation, please see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🔧 Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/geolab.git
    cd geolab/Geolab\ interfaces/geolab
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env` file in the root directory (see `.env.example` if available) and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📱 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend / Auth**: Supabase
- **State Management**: BLoC & Provider
- **Networking**: Dio
- **ML Integration**: Python (Backend API)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---
*Built with ❤️ for the Geology Community*
