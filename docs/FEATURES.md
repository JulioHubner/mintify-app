# Features

Mintify provides several tools for macOS storage management and system cleanup.

## Storage Cleaner

The main feature for cleaning junk files and cached data.

### Scanned Categories

| Category | Description | Paths |
|----------|-------------|-------|
| **User Caches** | Application caches | `~/Library/Caches/*` |
| **Browser Caches** | Safari, Chrome, Firefox | Browser-specific cache paths |
| **Logs** | Application logs | `~/Library/Logs/*` |
| **Xcode** | DerivedData, Archives, Device Support | `~/Library/Developer/Xcode/*` |
| **Developer Tools** | NPM, Yarn, Gradle, CocoaPods, pip | Various package manager caches |
| **Trash** | Items in user trash | `~/.Trash` |

### UI Features
- Category-based grouping with size breakdown
- Expand/collapse for detailed file lists
- Select all/individual items for cleaning
- Real-time scanning progress

---

## Duplicate Finder

Finds duplicate files based on content hash (MD5).

### Features
- Content-based duplicate detection
- Sort by size, name, or count
- Category filtering (images, documents, videos, etc.)
- Preview and compare duplicates

### Performance
- Uses MD5 hash for accurate content comparison
- Size-first filtering for efficiency
- Cancellable scan operation

---

## Large Files Finder

Identifies large files consuming disk space.

### Filter Options
- Size threshold (e.g., > 100MB, > 500MB, > 1GB)
- File type category filtering
- Custom size input

### Sort Options
- By size (ascending/descending)
- By name
- By modification date

---

## Disk Space Visualizer

Visual representation of disk usage.

### Features
- Treemap visualization
- Folder drill-down navigation
- Size percentage display
- System vs. user data breakdown

### Information Displayed
- Total disk capacity
- Used/free space
- Per-folder breakdown

---

## Memory Optimizer

Monitor and manage RAM usage.

### Features
- Real-time memory usage
- Process list with memory consumption
- Memory pressure indicator

---

## App Uninstaller

Complete application removal including leftover files.

### Features
- Lists all installed applications
- Shows app size and version
- Finds associated files:
  - Application Support files
  - Preferences (plist files)
  - Caches
  - Saved states
- Reveal leftover files in Finder
- Move apps to Trash

### Supported Locations
- `/Applications`
- `~/Applications`

---

## Menu Bar Quick Access

Lightweight popover from menu bar icon.

### Features
- System stats overview (CPU, Memory, Storage)
- Quick scan trigger
- Direct access to full app
- Compact footprint
