# App Icon Instructions

To create the app icon matching the login screen:

1. Create a 1024x1024 PNG image with:
   - A blue build/tool icon (like the one on the login screen: `Icons.build`)
   - Blue background color: #2196F3 (or transparent with blue icon)
   - The icon should be centered and clearly visible

2. Save it as `app_icon.png` in this directory (`assets/icon/app_icon.png`)

3. Run these commands:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

The icon will automatically be generated for all Android densities.

**Icon Requirements:**
- Format: PNG
- Size: 1024x1024 pixels minimum
- Background: Blue (#2196F3) or transparent
- Icon: Build/tool icon in white or lighter blue for contrast

You can create this icon using:
- Online tools like https://www.favicon-generator.org/
- Design tools like Figma, Canva, or Photoshop
- Icon generator tools that can convert Flutter Material Icons to PNG

