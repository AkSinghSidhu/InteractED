# InterActED - Interactive Learning Tool

InterActED is a cross-platform mobile application (built with Flutter) designed to help students visualize and understand complex Computer Science concepts through interactive simulations.

## 🚀 Features

The application covers various subjects, offering interactive modules for:

### 🖥️ Computers
*   **Artificial Intelligence**
    *   **BFS & DFS Visualizer:** Interactive graph traversal simulation where you can add nodes, edges, and watch Breadth-First Search and Depth-First Search algorithms in action.
*   **Operating Systems**
    *   **Virtual Memory (Paging & TLB):** A complete simulation of how the CPU translates virtual addresses, uses the TLB cache, handles page faults, and manages RAM/Disk swapping with FIFO and LRU eviction policies.
*   **Database Systems**
    *   **B+ Tree Indexing:** Visualization of B+ Tree insertion logic, showing how data is structured and how nodes split upon overflow.
*   **Computer Networks**
    *   **OSI Model:** An interactive layer-by-layer breakdown of the OSI model, visualizing encapsulation and decapsulation of data.
*   **Cybersecurity**
    *   **Encryption:** Visual demo of Symmetric vs Asymmetric encryption flows.
    *   **ARP Spoofing (MITM):** Simulation of a Man-in-the-Middle attack showing how ARP poisoning redirects traffic.

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **State Management:** `ValueNotifier` for global theme management.
*   **Animations:** `AnimationController`, `Tween`, and custom `Canvas` painters for high-performance visualizations.
*   **Design:** Material 3 with a custom light/dark theme system.

## 📸 Screenshots

*(Add screenshots of your app here)*

## 📦 Installation

1.  **Prerequisites:** Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/interacted.git
    cd interacted
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
