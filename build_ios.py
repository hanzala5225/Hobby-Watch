import os, re, plistlib, shutil, subprocess, glob

# Find profile
profile_dir = os.path.expanduser("~/Library/Developer/Xcode/UserData/Provisioning Profiles")
profiles = [f for f in os.listdir(profile_dir) if f.endswith(".mobileprovision")]
profile_path = os.path.join(profile_dir, profiles[0])
print(f"Profile: {profile_path}")

# Parse profile
with open(profile_path, "rb") as f:
    content = f.read()
start = content.find(b"<?xml")
end = content.find(b"</plist>") + 8
plist = plistlib.loads(content[start:end])
uuid = plist["UUID"]
name = plist["Name"]
print(f"UUID: {uuid}")
print(f"Name: {name}")

# Install with UUID filename
mobile_dir = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")
os.makedirs(mobile_dir, exist_ok=True)
shutil.copy2(profile_path, os.path.join(mobile_dir, f"{uuid}.mobileprovision"))
shutil.copy2(profile_path, os.path.join(profile_dir, f"{uuid}.mobileprovision"))
print("Profiles installed")

# Find Codemagic keychain and add to search list
keychain_dir = os.path.expanduser("~/Library/codemagic-cli-tools/keychains")
keychains = glob.glob(f"{keychain_dir}/*.keychain-db")
if keychains:
    cm_keychain = keychains[0]
    print(f"Codemagic keychain: {cm_keychain}")
    # Get current keychain list
    result = subprocess.run(["security", "list-keychains"], capture_output=True, text=True)
    current = result.stdout.strip()
    print(f"Current keychains: {current}")
    # Add codemagic keychain to search list
    subprocess.run([
        "security", "list-keychains", "-d", "user", "-s",
        cm_keychain,
        os.path.expanduser("~/Library/Keychains/login.keychain-db")
    ])
    # Unlock it
    subprocess.run(["security", "unlock-keychain", cm_keychain])
    print("Keychain added to search list and unlocked")
else:
    print("WARNING: No Codemagic keychain found!")

# Write ExportOptions
export_options = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>46CH6J94CY</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.hobbywatch.appios</key>
        <string>PROFILE_NAME_PLACEHOLDER</string>
    </dict>
</dict>
</plist>""".replace("PROFILE_NAME_PLACEHOLDER", name)

with open("/tmp/ExportOptions.plist", "w") as f:
    f.write(export_options)
print(f"ExportOptions written with profile: {name}")

# Run flutter build ipa --no-codesign first
result = subprocess.run(
    ["flutter", "build", "ipa", "--release", "--no-codesign"],
    capture_output=False
)
print(f"flutter build ipa --no-codesign exit code: {result.returncode}")

# Patch project.pbxproj AFTER flutter's internal pod install
pbxproj = "ios/Runner.xcodeproj/project.pbxproj"
with open(pbxproj, "r") as f:
    proj = f.read()
proj = re.sub(r'\t+PROVISIONING_PROFILE = ".*?";\n', "", proj)
proj = re.sub(r'\t+PROVISIONING_PROFILE_SPECIFIER = ".*?";\n', "", proj)
target_id = '97C147071CF9000F007C117D /* Release */'
idx = proj.find(target_id)
if idx >= 0:
    bs_idx = proj.find("buildSettings = {", idx)
    end_idx = proj.find("\n\t\t\t};", bs_idx)
    inject = f'\t\t\t\tPROVISIONING_PROFILE = "{uuid}";\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{name}";\n'
    proj = proj[:end_idx] + inject + proj[end_idx:]
    print("Injected profile into Runner Release target only")
with open(pbxproj, "w") as f:
    f.write(proj)

# Archive - no global profile flags, keychain is in search list
result2 = subprocess.run([
    "xcodebuild",
    "-workspace", "ios/Runner.xcworkspace",
    "-scheme", "Runner",
    "-configuration", "Release",
    "-archivePath", "/tmp/Runner.xcarchive",
    "archive",
    "CODE_SIGN_IDENTITY=Apple Distribution",
    "DEVELOPMENT_TEAM=46CH6J94CY",
    "CODE_SIGN_STYLE=Manual",
    "OTHER_CODE_SIGN_FLAGS=--keychain " + (keychains[0] if keychains else ""),
], capture_output=False)
print(f"xcodebuild archive exit: {result2.returncode}")

if result2.returncode == 0:
    result3 = subprocess.run([
        "xcodebuild",
        "-exportArchive",
        "-archivePath", "/tmp/Runner.xcarchive",
        "-exportOptionsPlist", "/tmp/ExportOptions.plist",
        "-exportPath", "build/ios/ipa",
    ], capture_output=False)
    print(f"xcodebuild export exit: {result3.returncode}")
    if result3.returncode != 0:
        exit(1)
else:
    exit(1)