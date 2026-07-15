# Atlas
### Mini AI chatbot application for Windows, made with Flutter

<p align="center">
  <img width="321" height="444" alt="Left Image" src="https://github.com/user-attachments/assets/83e22c90-1b27-463d-be14-bfdc74b13a67" />
  &nbsp;&nbsp;&nbsp;
  <img width="321" height="444" alt="image" src="https://github.com/user-attachments/assets/4f424762-6f4f-4fba-b498-89bf0150c6fa" />
  &nbsp;&nbsp;&nbsp;
  <img width="321" height="444" alt="image" src="https://github.com/user-attachments/assets/1697ff75-baeb-4988-8ea3-8c7cfcfdbc0f" />
</p>


## Purpose
The purpose of the application is to have quickly accessible AI straight from your taskbar. The app lives in your system tray and launches in the corner of your screen. 

<img width="210" height="102" alt="image" src="https://github.com/user-attachments/assets/6a6d7e02-ed98-42b8-89ea-5a11fcc6c1bf" />

## Framework
The app is built with Flutter, with Windows as the only target platform. Plugins such as `tray_manager`, `provider`, `flutter_markdown` and `flutter_acrylic` have been used. Thanks to Flutter, we achieve aesthetically pleasing visuals, fluid animations and overall an app with high performance. The fonts `Google Sans` and `JetBrains Mono` have been used for the interface. The plugin `flutter_markdown` implements support for text formatting (**bold**, *italic*, etc.) which LLMs generally include in their responses.

## The AI Backend
The LLM used for this project, as seen in the images, is **Meta's Llama Scout 4**. The API requests are done through the service **Groq**.
- **You will need to add your own Groq API Key into the source if you want to run the application yourself.**

<img width="337" height="211" alt="image" src="https://github.com/user-attachments/assets/d654c098-510e-41ff-b4a0-22128636fc10" />

_*Screenshot taken on the Groq website_
