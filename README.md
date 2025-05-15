## ADB Batch Manager

A Windows batch script to simplify installing and uninstalling Android APKs on connected devices via ADB. Users can select from a list of URLs or package names defined in a TXT file and target one of multiple connected devices.

---

### Features

* **Install mode**: Downloads APKs from a URL list file and installs them on the selected device.
* **Uninstall mode**: Reads package names from a TXT file and uninstalls them from the selected device.
* **Device selection**: Detects multiple connected devices and allows selection by serial number.
* **Colored console output**: Uses ANSI escape codes for clear status messages and highlighting.
* **Flexible input**: Supports installing/uninstalling all entries or a subset chosen by the user.

---

### Prerequisites

* **Windows 10 or later**
* **ADB (Android Debug Bridge)** installed and added to your PATH. Download from the Android SDK Platform-Tools: [https://developer.android.com/studio/releases/platform-tools](https://developer.android.com/studio/releases/platform-tools)
* **PowerShell** available (built into Windows) for downloading files via `Invoke-WebRequest`.
* A text editor to edit or create your `.txt` list files.

---

### Setup

1. **Clone or download** this repository (named `adbuniversal`) from GitHub to your local machine.
2. **Place** your list files (`.txt`) in the same folder as the batch script. Each line in the file should be either:

   * A direct URL to an APK file (for install mode)
   * A package name (for uninstall mode)
3. **Open PowerShell or Command Prompt** in the script directory.
4. **Run** the script:

   ```bat
   adbuniversal.bat
   ```

---

### Usage

1. **Choose an action**:

   * `1` — Install APKs from a URL list
   * `2` — Uninstall packages
   * `3` — Exit script
2. **Select a list file** by number. The script auto-detects any `.txt` files in its folder.
3. **Select a device** by number if multiple are connected.
4. **For install mode**:

   * Review the APK URLs found in the selected list file.
   * Enter `all` to process every URL, or type specific entry numbers separated by spaces (e.g., `1 3 5`).
   * The script downloads each APK to a temporary folder and installs it with `adb install -r`.
5. **For uninstall mode**:

   * Review the package names in the list file.
   * Enter `all` or specific entry numbers to uninstall.
   * The script invokes `adb shell pm uninstall --user 0 <package>` for each selected package.
6. **Completion**: A summary message appears once operations finish; press any key to return to the main menu.

---

### Customization

* **Colors & formatting**: Modify the ANSI code variables at the top of the script to change text colors.
* **Download method**: Replace the PowerShell `Invoke-WebRequest` call with `curl` or other download utilities if preferred.
* **Default branch**: Ensure your default branch on GitHub is set to `main` or adjust push commands accordingly.

---

### Troubleshooting

* **No devices detected**: Verify USB debugging is enabled on the device and drivers are properly installed.
* **Failed downloads**: Check the URLs in your list file are accessible. You can test them manually in a browser.
* **Permission errors**: Run the script with administrator rights if encountering file write or ADB permission issues.

---

### License & Author

* **Author**: Your Name
* **License**: MIT License (see `LICENSE` file)

---

*Copy and paste this README.md into your GitHub repository before your first commit!*
