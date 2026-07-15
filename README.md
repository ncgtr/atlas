# Atlas
### Mini AI chatbot application for Windows, made with Flutter

<p align="center">
  <img width="321" height="444" src="https://github.com/user-attachments/assets/eef02f28-ee6f-4d64-9916-bef0c4624561" />
  &nbsp;&nbsp;&nbsp;
  <img width="321" height="444" src="https://github.com/user-attachments/assets/b316b67c-84c9-4e93-82d4-ab16ead3c396" />
  &nbsp;&nbsp;&nbsp;
  <img width="321" height="444" src="https://github.com/user-attachments/assets/00b16b24-392d-456d-a985-4a78f020b557" />
</p>


## Purpose
The purpose of the application is to have quickly accessible AI straight from your taskbar. The app lives in your system tray and launches in the corner of your screen. 

<img width="194" height="74" alt="image" src="https://github.com/user-attachments/assets/b422056c-28ee-4f42-b26d-ef2682f1734d" />

## Framework
The app is built with Flutter, with Windows as the only target platform. Plugins such as `tray_manager`, `provider`, `flutter_markdown` and `flutter_acrylic` have been used. Thanks to Flutter, we achieve aesthetically pleasing visuals, fluid animations and overall an app with high performance. The fonts `Google Sans` and `JetBrains Mono` have been used for the interface. The plugin `flutter_markdown` implements support for text formatting (**bold**, *italic*, etc.) which LLMs generally include in their responses.

## The AI Backend
The LLM used for this project, as seen in the images, is **Meta's Llama Scout 4**. The API requests are done through the service **Groq**.
- **You will need your own Groq API Key if you wish to run the application.**

<img width="337" height="211" alt="image" src="https://github.com/user-attachments/assets/2aa484e7-bd84-4b26-980a-ecb3e933557c" />

_*Screenshot taken on the Groq website_
