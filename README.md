# Folder Diff Sync

**Folder Diff Sync** is a premium, high-performance desktop application built with Flutter, designed for fast and efficient folder comparison and synchronization. 

## Key Features

### 🔄 Dual Sync Modes
- **Folder & Subfolder Sync**: Keep entire directory structures in sync across different locations or drives. Perfect for backups and mirroring.
- **File Content Sync**: A specialized mode for managing configuration files (like `.env`). Generate templates, strip values, and manage environment-specific settings with ease.

### ⚡ High-Performance Comparison
- **Progressive Scanning**: Uses background isolates to scan thousands of files without blocking the UI.
- **Real-time Discovery**: Watch as files are discovered and categorized into the transfer queue in real-time.
- **Intelligent Detection**: Automatically identifies missing files (source/target), size differences, and identical files.

### 🎨 Premium User Experience
- **Modern Design**: A beautiful, dark-themed interface featuring glassmorphism, smooth animations, and a sleek, multi-split view layout.
- **Full Control**: Select exactly which files or folders to include in your sync operation.
- **Two-Way Sync**: Support for bi-directional synchronization to keep both locations perfectly updated.

### 🛡️ Safety & Precision
- **Visual Status Markers**: Clear icons and labels for missing, different, or identical items.
- **Transfer Queue Management**: Search and sort your synchronization tasks by name, size, or status.

## Getting Started

1. **Build the App**: `flutter build windows --release`
2. **Install**: Run the generated installer from the `installer/` directory.
3. **Select Folders**: Choose your Source and Target folders to begin the comparison.
