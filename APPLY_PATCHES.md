# Leaves Patches Application Guide for Onikiri 1.21.1

## Overview
This guide explains how to apply Leaves patches to Paper 1.21.1 with conflict handling.

## Prerequisites
- Git installed and configured
- Onikiri repository cloned locally
- Java Development Kit (JDK) 21+
- Gradle (included via gradlew)

## Quick Start

### Step 1: Navigate to Repository
```bash
cd path/to/Onikiri
git checkout leaves-patches-1.21.1
```

### Step 2: Make Script Executable
```bash
chmod +x apply_patches.sh
```

### Step 3: Apply Patches
```bash
./apply_patches.sh
```

### Step 4: Handle Conflicts (if any)
If conflicts occur:
1. Review the generated `CONFLICTS.log`
2. Look for `.rej` files in the repository
3. Manually merge conflicts into source files
4. Delete `.rej` files when done
5. Commit changes: `git add . && git commit -m "Resolve patch conflicts"`

## Patches Included (1-16)

| # | Name | Purpose |
|---|------|---------|
| 1 | Build changes | Branding and version changes |
| 2 | Delete Timings | Remove timing overhead |
| 3 | Leaves Server Config | Config system integration |
| 4 | Leaves Protocol Core | Protocol handling |
| 5 | Leaves Fakeplayer | Bot/Fakeplayer support |
| 6 | No chat sign | Chat signing modification |
| 7 | MC Technical Survival Mode | Technical mode support |
| 8 | Leaves Extra Yggdrasil Service | Authentication extension |
| 9 | Disable packet limit | Packet rate limit control |
| 10 | Replay Mod API | Replay functionality |
| 11 | Force minecraft command | Command handling |
| 12 | Bytebuf API | Buffer utilities |
| 13 | Leaves Plugin | Plugin system |
| 14 | Fix SculkCatalyst exp skip | Experience bug fix |
| 15 | Leaves Config API | Configuration API |
| 16 | Old ender dragon part can use end portal | Dragon behavior |

## Common Issues and Solutions

### Issue: "Conflict in patch X"
**Solution:**
```bash
# Check what conflicts occurred
cat CONFLICTS.log

# Find .rej files
find . -name "*.rej"

# Manually edit the source file and merge changes
# Then remove the .rej file
rm path/to/file.rej
```

### Issue: "Apply error"
**Solution:**
- The patch format may be incompatible
- Check if the file exists in Paper 1.21.1
- Manually apply the changes described in the patch

### Issue: Version mismatch
**Solution:**
- Ensure you're on Paper 1.21.1
- Some changes may need manual adaptation for API differences

## Building After Patches

### Step 1: Setup Gradle
```bash
./gradlew applyPatches
```

### Step 2: Build
```bash
./gradlew build
```

### Step 3: Locate JAR
```bash
# Server JAR
build/libs/paper-server-1.21.1-*.jar

# API JAR
build/libs/paper-api-1.21.1-*.jar
```

## Troubleshooting Build Failures

### Error: "Cannot resolve symbol"
- Missing Leaves classes need to be implemented
- Create the required Java classes in appropriate packages

### Error: "Compilation failed"
- Some patches may reference classes that don't exist in Paper 1.21.1
- Manually implement stubs or adapt the patches

### Error: "Test failures"
- Run tests separately to identify issues
- Some tests may need updating for Leaves changes

## Next Steps

After successful patch application and build:
1. Test the server locally
2. Verify all Leaves features work
3. Create a release with the built JAR
4. Document any modifications made

## Support

For issues specific to:
- **Leaves patches**: https://github.com/LeavesMC/Leaves
- **Paper base**: https://github.com/PaperMC/Paper
- **This fork**: Check GitHub issues

## Patch Application Log

After running `apply_patches.sh`, check:
- `CONFLICTS.log` - List of patches with conflicts
- Console output - Real-time status
- `.rej` files - Actual conflict markers
