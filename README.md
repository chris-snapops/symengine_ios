# symengine_ios
Builds a CPP Symengine .xcframework for iOS development.

### Steps to use
 1. Clone to your mac with `git clone https://github.com/chris-snapops/symengine_ios.git`
 2. Change the name of `template.env` to just `.env`
 3. Run `security find-identity -v -p codesigning` to get your `CODESIGN_IDENTITY`
    - i.e. `DEA333EBE133333D33D70E3333EFED018C8866F1`
 4. In `.env`, rename the variables
 5. Run `sudo chmod +x create_symengine_framework.sh gmp_install.sh symengine_install.sh` to enable the scripts as executables
 6. Run `./create_symengine_framework.sh`
    - This will take several minutes.  If you see red text, there's been an error.  If not, everything's going well!
 7. Once that's complete, it will say "XCFrameworks created at..."
 8. Copy the frameworks above into your Xcode iOS project
    - Anywhere is fine, ideally under the /Frameworks
 9. In the root directory directory, create a new folder called src and paste everything from symengine_src into there
10. In the project settings > project_name (choose the whole project, not the target) > General > Frameworks and Libraries, set both xcframeworks to "Embed and Sign"
11. In the project settings > project_name > Build Settings  
    1. search "bridging header"
    2. set Objective-C Bridging Header to `$(PROJECT_DIR)/src/snapcalc-Bridging-Header.h`
12. In the project settings > project_name > Build Settings
    1. search "runpath search paths"
    2. set Runpath Search Paths to "@executable_path/Frameworks"
12. go ahead and build!

##
### Other notes
 - Only runs on macOS.  Shouldn't be an issue since you're building for iOS lol
 - Default versions are found in versions.sh

##
### Credit
 - Heavily inspired by Osama Mazhar's git repo and youtube video.
    - https://github.com/OsamaMazhar/iOS-framework-cmake
    - https://www.youtube.com/watch?v=TdrZ7x_W-9M