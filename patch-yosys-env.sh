#!/bin/sh
set -e

# Find the init_share_dirname function and add our code
if ! grep -q "getenv.*YOSYS_DATDIR" kernel/yosys.cc; then
    echo "Patching init_share_dirname function"

    # Create temporary patch content
    cat >/tmp/env_patch.txt <<'PATCH'
    // Check environment variable first (cross-platform)
    const char* env_datdir = getenv("YOSYS_DATDIR");
    if (env_datdir) {
        std::string proc_share_path = std::string(env_datdir);
        
#if defined(_WIN32) && !defined(YOSYS_WIN32_UNIX_DIR)
        if (!proc_share_path.empty() && proc_share_path.back() != '\\') {
            proc_share_path += "\\";
        }
#else
        if (!proc_share_path.empty() && proc_share_path.back() != '/') {
            proc_share_path += "/";
        }
#endif
        
        if (check_directory_exists(proc_share_path, true)) {
            yosys_share_dirname = proc_share_path;
            return;
        }
    }

PATCH

    # Insert after line 545
    sed -i '545r /tmp/env_patch.txt' kernel/yosys.cc

    rm /tmp/env_patch.txt
    echo "Environment variable patch applied successfully!"
else
    echo "Patch already applied, skipping..."
fi
